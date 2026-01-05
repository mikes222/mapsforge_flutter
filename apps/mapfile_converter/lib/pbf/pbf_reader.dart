import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbfproto/fileformat.pb.dart';
import 'package:mapfile_converter/pbfproto/osmformat.pb.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';

abstract class IPbfReader {
  void dispose();

  Future<OsmData?> readBlobData(int position);

  Future<BoundingBox?> calculateBounds();

  Future<List<int>> getBlobPositions();
}

//////////////////////////////////////////////////////////////////////////////

@pragma("vm:entry-point")
class IsolatePbfReader implements IPbfReader {
  final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolatePbfReader._();

  static Future<IsolatePbfReader> create({required ReadbufferSource readbufferSource, required int sourceLength}) async {
    PbfReaderInstanceRequest request = PbfReaderInstanceRequest(readbufferSource: readbufferSource, sourceLength: sourceLength);
    IsolatePbfReader instance = IsolatePbfReader._();
    await instance._isolateInstance.spawn(createInstance, request);
    return instance;
  }

  @override
  void dispose() {
    _isolateInstance.dispose();
  }

  @override
  Future<OsmData?> readBlobData(int position) async {
    return _isolateInstance.compute(position);
  }

  @override
  Future<BoundingBox?> calculateBounds() async {
    return _isolateInstance.compute(-2);
  }

  @override
  Future<List<int>> getBlobPositions() async {
    return _isolateInstance.compute(-3);
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static PbfReader? _pbfReader;

  @pragma('vm:entry-point')
  static Future<void> createInstance(IsolateInitInstanceParams<PbfReaderInstanceRequest> object) async {
    _pbfReader ??= PbfReader(readbufferSource: object.initObject!.readbufferSource, sourceLength: object.initObject!.sourceLength);
    await FlutterIsolateInstance.isolateInit(object, readBlobDataStatic);
  }

  @pragma('vm:entry-point')
  static Future<Object?> readBlobDataStatic(int param) async {
    if (param == -2) return _pbfReader!.calculateBounds();
    if (param == -3) return _pbfReader!.getBlobPositions();
    return _pbfReader!.readBlobData(param);
  }
}

//////////////////////////////////////////////////////////////////////////////

class PbfReaderInstanceRequest {
  final ReadbufferSource readbufferSource;

  final int sourceLength;

  PbfReaderInstanceRequest({required this.readbufferSource, required this.sourceLength});
}

//////////////////////////////////////////////////////////////////////////////

/// Reads data from a PBF file.
class PbfReader implements IPbfReader {
  HeaderBlock? headerBlock;

  final ReadbufferSource readbufferSource;

  final int sourceLength;

  PbfReader({required this.readbufferSource, required this.sourceLength});

  @override
  void dispose() {
    readbufferSource.dispose();
    headerBlock = null;
  }

  Future<BlobResult> _readBlob() async {
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

  @override
  Future<List<int>> getBlobPositions() async {
    List<int> result = [];
    // open first to get the correct position of the first blob
    await _open();
    while (readbufferSource.getPosition() < sourceLength) {
      result.add(readbufferSource.getPosition());
      await skipBlob();
    }
    await readbufferSource.setPosition(0);
    return result;
  }

  @override
  Future<OsmData> readBlobData(int position) async {
    await _open();
    await readbufferSource.setPosition(position);
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
    blobHeader.clear();
    readbuffer = await readbufferSource.readFromFile(blobLength);
    final blob = Blob.fromBuffer(readbuffer.getBuffer(0, blobLength));
    final blobOutput = ZLibDecoder().convert(blob.zlibData);
    assert(blobOutput.length == blob.rawSize);
    blob.clear();
    return _readBlock(blobOutput);
  }

  Future<void> skipBlob() async {
    // length of the blob header
    await _open();
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));

    final blobLength = blobHeader.datasize;
    blobHeader.clear();
    await readbufferSource.setPosition(readbufferSource.getPosition() + blobLength);
  }

  Future<void> _open() async {
    if (headerBlock != null) return;
    final blobResult = await _readBlob();
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

  @override
  Future<BoundingBox?> calculateBounds() async {
    if (headerBlock == null) return null;
    final bounds = (headerBlock!.bbox.bottom != 0 || headerBlock!.bbox.left != 0 || headerBlock!.bbox.top != 0 || headerBlock!.bbox.right != 0)
        ? BoundingBox(
            1e-9 * headerBlock!.bbox.bottom.toInt(),
            1e-9 * headerBlock!.bbox.left.toInt(),
            1e-9 * headerBlock!.bbox.top.toInt(),
            1e-9 * headerBlock!.bbox.right.toInt(),
          )
        : null;
    return bounds;
  }

  OsmData _readBlock(List<int> blobOutput) {
    final block = PrimitiveBlock.fromBuffer(blobOutput);
    List<String> stringTable = block.stringtable.s.map((s) => utf8.decode(s)).toList();
    final latOffset = block.latOffset.toInt();
    final lonOffset = block.lonOffset.toInt();
    final granularity = block.granularity;
    final primitiveGroups = block.primitivegroup;
    block.clear();
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
      for (final way in primitiveGroup.ways) {
        final id = way.id.toInt();
        var refDelta = 0;
        final refs = way.refs.map((ref) {
          refDelta += ref.toInt();
          return refDelta;
        }).toList();
        final tags = _parseParallelTags(way.keys, way.vals, stringTable);
        ways.add(OsmWay(id: id, refs: refs, tags: tags));
      }
      for (final relation in primitiveGroup.relations) {
        final id = relation.id.toInt();
        final tags = _parseParallelTags(relation.keys, relation.vals, stringTable);
        var refDelta = 0;
        final memberIds = relation.memids.map((ref) {
          refDelta += ref.toInt();
          return refDelta;
        }).toList();
        final types = relation.types.map((type) {
          return switch (type) {
            Relation_MemberType.NODE => MemberType.node,
            Relation_MemberType.WAY => MemberType.way,
            Relation_MemberType.RELATION => MemberType.relation,
            _ => throw Exception('Unknown member type: $type'),
          };
        }).toList();
        final roles = relation.rolesSid.map((role) {
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
      var j = 0;
      if (primitiveGroup.dense.id.isNotEmpty) {
        final dense = primitiveGroup.dense;
        var id = 0;
        var latDelta = 0;
        var lonDelta = 0;
        for (var i = 0; i < dense.id.length; ++i) {
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
    return OsmData(nodes: nodes, ways: ways, relations: relations);
  }

  Map<String, String> _parseParallelTags(List<int> keys, List<int> values, List<String> stringTable) {
    final tags = <String, String>{};
    assert(keys.length == values.length);
    keys.forEachIndexed((int index, int key) {
      if (key == 0) {
        return;
      }
      tags[stringTable[key]] = stringTable[values[index]];
    });
    return tags;
  }
}

//////////////////////////////////////////////////////////////////////////////

class BlobResult {
  final BlobHeader blobHeader;

  final List<int> blobOutput;

  BlobResult(this.blobHeader, this.blobOutput);
}
