import 'dart:convert';
import 'dart:io';

import 'package:mapfile_converter/pbfreader/pbf_data.dart';
import 'package:mapfile_converter/pbfreader/proto/fileformat.pb.dart';
import 'package:mapfile_converter/pbfreader/proto/osmformat.pb.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

/// Reads data from a PBF file.
class PbfReader {
  HeaderBlock? headerBlock;

  Future<BlobResult> readBlob(ReadbufferSource readbufferSource) async {
    // length of the blob header
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));
    // print("blobHeader: ${blobHeader.type}");
    // print("blobHeader.datasize: ${blobHeader.datasize}");
    // print("blobHeader.indexdata: ${blobHeader.indexdata}");
    // print("blobHeader.unknownFields: ${blobHeader.unknownFields}");

    final blobLength = blobHeader.datasize;
    readbuffer = await readbufferSource.readFromFile(blobLength);
    final blob = Blob.fromBuffer(readbuffer.getBuffer(0, blobLength));
    final blobOutput = ZLibDecoder().convert(blob.zlibData);
    assert(blobOutput.length == blob.rawSize);
    return BlobResult(blobHeader, blobOutput);
  }

  Future<PbfData> readBlobData(ReadbufferSource readbufferSource) async {
    // length of the blob header
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));
    // print("blobHeader: ${blobHeader.type}");
    // print("blobHeader.datasize: ${blobHeader.datasize}");
    // print("blobHeader.indexdata: ${blobHeader.indexdata}");
    // print("blobHeader.unknownFields: ${blobHeader.unknownFields}");

    final blobLength = blobHeader.datasize;
    readbuffer = await readbufferSource.readFromFile(blobLength);
    final blob = Blob.fromBuffer(readbuffer.getBuffer(0, blobLength));
    final blobOutput = ZLibDecoder().convert(blob.zlibData);
    assert(blobOutput.length == blob.rawSize);
    return readBlock(blobOutput);
  }

  Future<void> skipBlob(ReadbufferSource readbufferSource) async {
    // length of the blob header
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));

    final blobLength = blobHeader.datasize;
    await readbufferSource.setPosition(readbufferSource.getPosition() + blobLength);
  }

  Future<void> open(ReadbufferSource readbufferSource) async {
    final blobResult = await readBlob(readbufferSource);
    if (blobResult.blobHeader.type != 'OSMHeader') {
      throw Exception("Invalid file format OSMHeader expected");
    }
    headerBlock = HeaderBlock.fromBuffer(blobResult.blobOutput);
    // print("headerBlock.bbox: ${headerBlock!.bbox}");
    // print("headerBlock.requiredFeatures: ${headerBlock!.requiredFeatures}");
    // print("headerBlock.optionalFeatures: ${headerBlock!.optionalFeatures}");
    // print("headerBlock.writingprogram: ${headerBlock!.writingprogram}");
    // print("headerBlock.source: ${headerBlock!.source}");
    // print(
    //     "headerBlock.osmosisReplicationTimestamp: ${headerBlock!.osmosisReplicationTimestamp}");
    // print(
    //     "headerBlock.osmosisReplicationSequenceNumber: ${headerBlock!.osmosisReplicationSequenceNumber}");
    // print(
    //     "headerBlock.osmosisReplicationBaseUrl: ${headerBlock!.osmosisReplicationBaseUrl}");
  }

  BoundingBox? calculateBounds() {
    if (headerBlock == null) return null;
    final bounds =
        (headerBlock!.bbox.bottom != 0 || headerBlock!.bbox.left != 0 || headerBlock!.bbox.top != 0 || headerBlock!.bbox.right != 0)
            ? BoundingBox(
              1e-9 * headerBlock!.bbox.bottom.toInt(),
              1e-9 * headerBlock!.bbox.left.toInt(),
              1e-9 * headerBlock!.bbox.top.toInt(),
              1e-9 * headerBlock!.bbox.right.toInt(),
            )
            : null;
    return bounds;
  }

  PbfData readBlock(List<int> blobOutput) {
    final block = PrimitiveBlock.fromBuffer(blobOutput);
    List<String> stringTable = block.stringtable.s.map((s) => utf8.decode(s)).toList();
    final latOffset = block.latOffset.toInt();
    final lonOffset = block.lonOffset.toInt();
    final granularity = block.granularity;
    final primitiveGroups = block.primitivegroup;
    final nodes = <OsmNode>[];
    final ways = <OsmWay>[];
    final relations = <OsmRelation>[];
    for (final primitiveGroup in primitiveGroups) {
      if (primitiveGroup.changesets.isNotEmpty) {
        throw Exception('Changesets not supported');
      }
      if (primitiveGroup.nodes.isNotEmpty) {
        throw Exception('Nodes not supported');
      }
      if (primitiveGroup.ways.isNotEmpty) {
        for (final way in primitiveGroup.ways) {
          final id = way.id.toInt();
          var refDelta = 0;
          final refs =
              way.refs.map((ref) {
                refDelta += ref.toInt();
                return refDelta;
              }).toList();
          final tags = _parseParallelTags(way.keys, way.vals, stringTable);
          ways.add(OsmWay(id: id, refs: refs, tags: tags));
        }
      }
      if (primitiveGroup.relations.isNotEmpty) {
        for (final relation in primitiveGroup.relations) {
          final id = relation.id.toInt();
          final tags = _parseParallelTags(relation.keys, relation.vals, stringTable);
          var refDelta = 0;
          final memberIds =
              relation.memids.map((ref) {
                refDelta += ref.toInt();
                return refDelta;
              }).toList();
          final types =
              relation.types.map((type) {
                return switch (type) {
                  Relation_MemberType.NODE => MemberType.node,
                  Relation_MemberType.WAY => MemberType.way,
                  Relation_MemberType.RELATION => MemberType.relation,
                  _ => throw Exception('Unknown member type: $type'),
                };
              }).toList();
          final roles =
              relation.rolesSid.map((role) {
                return stringTable[role];
              }).toList();

          List<OsmRelationMember> members = [];
          for (int idx = 0; idx < memberIds.length; idx++) {
            int memberId = memberIds[idx];
            MemberType memberType = types[idx];
            String role = roles[idx];
            OsmRelationMember member = OsmRelationMember(memberId: memberId, memberType: memberType, role: role);
            members.add(member);
          }
          relations.add(OsmRelation(id: id, tags: tags, members: members));
        }
      }
      var j = 0;
      if (primitiveGroup.dense.id.isNotEmpty) {
        final dense = primitiveGroup.dense;
        var id = 0;
        var latDelta = 0;
        var lonDelta = 0;
        for (var i = 0; i < dense.id.length; i++) {
          id += dense.id[i].toInt();
          latDelta += dense.lat[i].toInt();
          lonDelta += dense.lon[i].toInt();
          final lat = 1e-9 * (latOffset + granularity * latDelta);
          final lon = (1e-9 * (lonOffset + granularity * lonDelta));
          final tags = <String, String>{};
          final keyVals = dense.keysVals;
          while (dense.keysVals[j] != 0) {
            tags[stringTable[keyVals[j]]] = stringTable[keyVals[j + 1]];
            j += 2;
          }
          j++;
          nodes.add(OsmNode(id: id, latitude: lat, longitude: lon, tags: tags));
        }
      }
    }
    return PbfData(nodes: nodes, ways: ways, relations: relations);
  }

  Map<String, String> _parseParallelTags(List<int> keys, List<int> values, List<String> stringTable) {
    final tags = <String, String>{};
    assert(keys.length == values.length);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] == 0) {
        continue;
      }
      tags[stringTable[keys[i]]] = stringTable[values[i]];
    }
    return tags;
  }
}

//////////////////////////////////////////////////////////////////////////////

class BlobResult {
  final BlobHeader blobHeader;

  final List<int> blobOutput;

  BlobResult(this.blobHeader, this.blobOutput);
}
