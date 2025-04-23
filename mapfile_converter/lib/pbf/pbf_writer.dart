import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:mapfile_converter/pbfproto/fileformat.pb.dart';
import 'package:mapfile_converter/pbfproto/osmformat.pb.dart' as osmformat;
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

import '../osm/osm_data.dart';
import '../pbfproto/osmformat.pb.dart';

class PbfWriter {
  late final SinkWithCounter sink;

  int _nextId = 0;

  final List<_DenseNode> _nodes = [];

  final List<_Way> _ways = [];

  final List<_Relation> _relations = [];

  PbfWriter(String filename, BoundingBox boundingBox) {
    sink = SinkWithCounter(File(filename).openWrite());

    HeaderBlock headerBlock = HeaderBlock(
      bbox: HeaderBBox(
        left: $fixnum.Int64(LatLongUtils.degreesToNanodegrees(boundingBox.minLongitude)),
        right: $fixnum.Int64(LatLongUtils.degreesToNanodegrees(boundingBox.maxLongitude)),
        top: $fixnum.Int64(LatLongUtils.degreesToNanodegrees(boundingBox.maxLatitude)),
        bottom: $fixnum.Int64(LatLongUtils.degreesToNanodegrees(boundingBox.minLatitude)),
      ),
      writingprogram: "Mapsforge Flutter",
    );
    _writeBlob(headerBlock.writeToBuffer(), type: "OSMHeader");
  }

  void _writeBlob(List<int> dataContent, {String type = "OSMData"}) {
    List<int> zlibContent = ZLibEncoder().convert(dataContent);
    Blob headerBlob = Blob(rawSize: dataContent.length, zlibData: zlibContent);
    List<int> headerBlobContent = headerBlob.writeToBuffer();

    BlobHeader header = BlobHeader();
    header.datasize = headerBlobContent.length;
    header.type = type;
    List<int> headerContent = header.writeToBuffer();

    // first 4 byte: length of blobHeader (0x0d)
    Writebuffer writebuffer = Writebuffer();
    writebuffer.appendInt4(headerContent.length);
    writebuffer.writeToSink(sink);
    // blob header
    sink.add(headerContent);
    sink.add(headerBlobContent);
  }

  Future<void> writeNode(ILatLong position, List<Tag> tags) async {
    _writeNode(position, tags);
  }

  _DenseNode _writeNode(ILatLong position, List<Tag> tags) {
    _DenseNode denseNode = _DenseNode(tags: tags, positions: [position], ids: [$fixnum.Int64(_nextId++)]);
    _nodes.add(denseNode);
    _tryWriteDenseNodes();
    return denseNode;
  }

  (List<int>, List<int>) _convertTags(List<Tag> tags, List<String> strings, StringTable stringTable) {
    if (strings.isEmpty) {
      // make sure index 0 is not used for productive purposes since 0 is a marker to skip tags
      stringTable.s.add(utf8.encode(""));
      strings.add("");
    }
    List<int> keys = [];
    List<int> values = [];
    for (var tag in tags) {
      if (strings.contains(tag.key!)) {
        keys.add(strings.indexOf(tag.key!));
      } else {
        keys.add(strings.length);
        strings.add(tag.key!);
        stringTable.s.add(utf8.encode(tag.key!));
      }
      if (strings.contains(tag.value!)) {
        values.add(strings.indexOf(tag.value!));
      } else {
        values.add(strings.length);
        strings.add(tag.value!);
        stringTable.s.add(utf8.encode(tag.value!));
      }
    }
    assert(keys.length == tags.length);
    assert(values.length == tags.length);
    return (keys, values);
  }

  void _tryWriteDenseNodes() {
    int count = _nodes.fold(0, (int count, _DenseNode combine) => count + combine.positions.length);
    if (count > 5000000) _writeDenseNodes();
  }

  void _writeDenseNodes() {
    if (_nodes.isEmpty) return;
    List<PrimitiveGroup> primitiveGroups = [];
    StringTable stringTable = StringTable();
    List<String> strings = [];
    $fixnum.Int64 latOffset = $fixnum.Int64(0); //$fixnum.Int64(LatLongUtils.degreesToNanodegrees(_nodes.first.positions.first.latitude));
    $fixnum.Int64 lonOffset = $fixnum.Int64(0); //$fixnum.Int64(LatLongUtils.degreesToNanodegrees(_nodes.first.positions.first.longitude));
    int granularity = 100;
    for (_DenseNode node in _nodes) {
      PrimitiveGroup primitiveGroup = PrimitiveGroup();
      DenseNodes denseNodes = DenseNodes();
      List<$fixnum.Int64> deltaIds = [];
      $fixnum.Int64 lastId = $fixnum.Int64(0);
      for (var id in node.ids) {
        deltaIds.add(id - lastId);
        lastId = id;
      }
      denseNodes.id.addAll(deltaIds);
      assert(node.ids.length == node.positions.length);
      $fixnum.Int64 lastLat = $fixnum.Int64(0);
      $fixnum.Int64 lastLon = $fixnum.Int64(0);
      for (var position in node.positions) {
        $fixnum.Int64 lat = $fixnum.Int64(LatLongUtils.degreesToNanodegrees(position.latitude / granularity));
        $fixnum.Int64 lon = $fixnum.Int64(LatLongUtils.degreesToNanodegrees(position.longitude / granularity));
        denseNodes.lat.add(lat - lastLat - latOffset);
        denseNodes.lon.add(lon - lastLon - lonOffset);
        lastLat = lat;
        lastLon = lon;
      }
      final (List<int> keys, List<int> values) = _convertTags(node.tags, strings, stringTable);
      assert(keys.length == values.length);
      for (int i = 0; i < node.ids.length; ++i) {
        for (int i = 0; i < keys.length; ++i) {
          denseNodes.keysVals.add(keys[i]);
          denseNodes.keysVals.add(values[i]);
        }
        denseNodes.keysVals.add(0);
      }
      primitiveGroup.dense = denseNodes;
      primitiveGroups.add(primitiveGroup);
    }
    PrimitiveBlock primitiveBlock = PrimitiveBlock(
      primitivegroup: primitiveGroups,
      stringtable: stringTable,
      latOffset: latOffset,
      lonOffset: lonOffset,
      granularity: granularity,
    );
    _writeBlob(primitiveBlock.writeToBuffer());
    _nodes.clear();
  }

  void _writeWays() {
    if (_ways.isEmpty) return;
    const int maxWaysPerGroup = 200000;
    StringTable stringTable = StringTable();
    List<String> strings = [];
    PrimitiveGroup primitiveGroup = PrimitiveGroup();
    for (_Way way in _ways.take(maxWaysPerGroup)) {
      final (List<int> keys, List<int> values) = _convertTags(way.tags, strings, stringTable);
      assert(way.refs.length >= 2);
      List<$fixnum.Int64> newRefs = [];
      $fixnum.Int64 refDelta = $fixnum.Int64(0);
      for (var ref in way.refs) {
        newRefs.add(ref - refDelta);
        refDelta = ref;
      }
      osmformat.Way osmWay = osmformat.Way(id: way.id, keys: keys, vals: values, refs: newRefs);
      primitiveGroup.ways.add(osmWay);
    }
    PrimitiveBlock primitiveBlock = PrimitiveBlock(stringtable: stringTable, primitivegroup: [primitiveGroup]);
    _writeBlob(primitiveBlock.writeToBuffer());
    if (_ways.length > maxWaysPerGroup) {
      _ways.removeRange(0, maxWaysPerGroup);
      _writeWays();
    }
    _ways.clear();
  }

  void _writeRelations() {
    const int maxRelationsPerGroup = 5000;
    if (_relations.isEmpty) return;
    StringTable stringTable = StringTable();
    List<String> strings = [];
    PrimitiveGroup primitiveGroup = PrimitiveGroup();
    for (_Relation relation in _relations.take(maxRelationsPerGroup)) {
      final (List<int> keys, List<int> values) = _convertTags(relation.tags, strings, stringTable);
      assert(keys.isNotEmpty);
      assert(values.isNotEmpty);
      List<Relation_MemberType> types = [];
      List<$fixnum.Int64> memids = [];
      $fixnum.Int64 lastId = $fixnum.Int64(0);
      List<int> rolesSid = [];
      for (OsmRelationMember member in relation.osmRelationMembers) {
        switch (member.memberType) {
          case MemberType.node:
            types.add(Relation_MemberType.NODE);
            break;
          case MemberType.way:
            types.add(Relation_MemberType.WAY);
          case MemberType.relation:
            throw UnimplementedError();
        }

        memids.add($fixnum.Int64(member.memberId) - lastId);
        lastId = $fixnum.Int64(member.memberId);

        if (strings.contains(member.role)) {
          rolesSid.add(strings.indexOf(member.role));
        } else {
          rolesSid.add(strings.length);
          strings.add(member.role);
          stringTable.s.add(utf8.encode(member.role));
        }
      }
      osmformat.Relation osmRelation = osmformat.Relation(
        id: $fixnum.Int64(_nextId++),
        keys: keys,
        vals: values,
        types: types,
        memids: memids,
        rolesSid: rolesSid,
      );
      primitiveGroup.relations.add(osmRelation);
    }
    assert(stringTable.s.isNotEmpty);
    assert(strings.isNotEmpty);
    assert(stringTable.s.length == strings.length);
    PrimitiveBlock primitiveBlock = PrimitiveBlock(stringtable: stringTable, primitivegroup: [primitiveGroup]);
    _writeBlob(primitiveBlock.writeToBuffer());
    if (_relations.length > maxRelationsPerGroup) {
      _relations.removeRange(0, maxRelationsPerGroup);
      _writeRelations();
    }
    _relations.clear();
  }

  _Way _writeWayOnePath(List<Tag> tags, Waypath waypath) {
    const int maxWaysPerGroup = 100000;
    List<$fixnum.Int64> allrefs = [];
    List<ILatLong> path = List.from(waypath.path);
    while (path.length > maxWaysPerGroup) {
      List<ILatLong> path2 = path.sublist(0, maxWaysPerGroup);
      path.removeRange(0, maxWaysPerGroup);
      List<$fixnum.Int64> refs = List.generate(path2.length, (idx) {
        return $fixnum.Int64(_nextId++);
      });
      allrefs.addAll(refs);
      // do not write tags for the nodes, we have them at the way-level
      _DenseNode denseNode = _DenseNode(tags: [], positions: path2, ids: refs);
      _nodes.add(denseNode);
      _tryWriteDenseNodes();
    }
    if (path.isNotEmpty) {
      List<$fixnum.Int64> refs = List.generate(path.length, (idx) {
        return $fixnum.Int64(_nextId++);
      });
      allrefs.addAll(refs);
      // do not write tags for the nodes, we have them at the way-level
      _DenseNode denseNode = _DenseNode(tags: [], positions: path, ids: refs);
      _nodes.add(denseNode);
      _tryWriteDenseNodes();
    }

    _Way way = _Way(id: $fixnum.Int64(_nextId++), tags: tags, refs: allrefs);
    _ways.add(way);
    return way;
  }

  Future<void> writeWay(Wayholder wayholder) async {
    if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.length + wayholder.closedOutersRead.length == 1 && wayholder.labelPosition == null) {
      // we do not need a relation
      Waypath waypath = wayholder.openOutersRead.isNotEmpty ? wayholder.openOutersRead.first : wayholder.closedOutersRead.first;
      _writeWayOnePath(wayholder.tags, waypath);
    } else {
      List<OsmRelationMember> members = [];
      for (Waypath waypath in wayholder.innerRead) {
        _Way way = _writeWayOnePath([], waypath);
        members.add(OsmRelationMember(memberId: way.id.toInt(), memberType: MemberType.way, role: "inner"));
      }
      for (Waypath waypath in wayholder.closedOutersRead) {
        _Way way = _writeWayOnePath([], waypath);
        members.add(OsmRelationMember(memberId: way.id.toInt(), memberType: MemberType.way, role: "outer"));
      }
      for (Waypath waypath in wayholder.openOutersRead) {
        _Way way = _writeWayOnePath([], waypath);
        members.add(OsmRelationMember(memberId: way.id.toInt(), memberType: MemberType.way, role: "outer"));
      }
      if (wayholder.labelPosition != null) {
        _DenseNode node = _writeNode(wayholder.labelPosition!, []);
        members.add(OsmRelationMember(memberId: node.ids.first.toInt(), memberType: MemberType.node, role: "label"));
      }
      assert(wayholder.tags.isNotEmpty);
      _Relation relation = _Relation(tags: wayholder.tags, osmRelationMembers: members);
      _relations.add(relation);
    }
  }

  Future<void> close() async {
    _writeDenseNodes();
    _writeWays();
    _writeRelations();
    await sink.flush();
    await sink.close();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _DenseNode {
  final List<Tag> tags;

  final List<ILatLong> positions;

  final List<$fixnum.Int64> ids;

  _DenseNode({required this.tags, required this.positions, required this.ids});
}

//////////////////////////////////////////////////////////////////////////////

class _Way {
  final List<Tag> tags;

  final List<$fixnum.Int64> refs;

  final $fixnum.Int64 id;

  _Way({required this.id, required this.tags, required this.refs});
}

//////////////////////////////////////////////////////////////////////////////

class _Relation {
  final List<Tag> tags;

  final List<OsmRelationMember> osmRelationMembers;

  _Relation({required this.tags, required this.osmRelationMembers});
}
