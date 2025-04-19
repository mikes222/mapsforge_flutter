import 'dart:convert';
import 'dart:io';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

class OsmWriter {
  late final IOSink _sink;

  int _currentIdent = 0;

  int _nextId = 0;

  final List<_Way> _ways = [];

  final List<_Way> _relations = [];

  final String tempFilename = 'temp_${DateTime.now().millisecondsSinceEpoch}.osm';

  IOSink? _tempSink;

  OsmWriter(String filename, BoundingBox boundingBox) {
    File file = File(filename);
    _sink = file.openWrite();
    _writeString('<?xml version="1.0" encoding="UTF-8"?>', _sink);
    _writeString('<osm version="0.6" generator="mapsforge_osm_writer">', _sink);
    ++_currentIdent;
    _writeBounds(boundingBox, _sink);
  }

  void _writeBounds(BoundingBox boundingBox, IOSink sink) {
    _writeString(
      '<bounds minlat="${boundingBox.minLatitude}" minlon="${boundingBox.minLongitude}" maxlat="${boundingBox.maxLatitude}" maxlon="${boundingBox.maxLongitude}" />',
      sink,
    );
  }

  int writeNode(ILatLong node, List<Tag> tags) {
    if (tags.isEmpty) {
      _writeString('<node id="$_nextId" lat="${node.latitude}" lon="${node.longitude}"/>', _sink);
    } else {
      _writeString('<node id="$_nextId" lat="${node.latitude}" lon="${node.longitude}">', _sink);
      _writeTags(tags, _sink);
      _writeString('</node>', _sink);
    }
    return _nextId++;
  }

  void writeWay(Wayholder wayholder) {
    assert(wayholder.tags.isNotEmpty);
    _Way _way = _Way(wayholder.tags);
    for (var waypath in wayholder.innerRead) {
      List<int> nodes = _writeNodesForWay(waypath);
      _way.addNodes(nodes);
    }
    for (var waypath in wayholder.closedOutersRead) {
      List<int> nodes = _writeNodesForWay(waypath);
      _way.addOuterNodes(nodes);
    }
    for (var waypath in wayholder.openOutersRead) {
      List<int> nodes = _writeNodesForWay(waypath);
      _way.addOuterNodes(nodes);
    }
    _ways.add(_way);
    if (_ways.length >= 1000) {
      _tempSink ??= File(tempFilename).openWrite();
      _writeWays(_tempSink!);
    }
  }

  List<int> _writeNodesForWay(Waypath waypath) {
    List<int> nodes = [];
    bool closed = waypath.isClosedWay();
    if (closed) {
      int firstId = writeNode(waypath.path.first, []);
      nodes.add(firstId);
      for (var latLong in waypath.path.skip(1).take(waypath.path.length - 2)) {
        nodes.add(writeNode(latLong, []));
      }
      nodes.add(firstId);
    } else {
      for (var latLong in waypath.path) {
        nodes.add(writeNode(latLong, []));
      }
    }
    return nodes;
  }

  void _writeTags(List<Tag> tags, IOSink sink) {
    ++_currentIdent;
    for (var tag in tags) {
      _writeString('<tag k="${const HtmlEscape().convert(tag.key!)}" v="${const HtmlEscape().convert(tag.value!)}"/>', sink);
    }
    --_currentIdent;
  }

  int _writeWay(List<int> nodes, List<Tag> tags, IOSink sink) {
    _writeString('<way id="$_nextId">', sink);
    ++_currentIdent;
    for (var node in nodes) {
      _writeString('<nd ref="$node"/>', sink);
    }
    --_currentIdent;
    _writeTags(tags, sink);
    _writeString('</way>', sink);
    return _nextId++;
  }

  int _writeRelation(List<int> members, List<int> outerMembers, List<Tag> tags) {
    _writeString('<relation id="$_nextId">', _sink);
    ++_currentIdent;
    int idx = 0;
    for (var member in members) {
      if (idx == 0) {
        _writeString('<member type="way" ref="$member" role="outer"/>', _sink);
      } else {
        _writeString('<member type="way" ref="$member" role="inner"/>', _sink);
      }
      ++idx;
    }
    for (var member in outerMembers) {
      _writeString('<member type="way" ref="$member" role="outer"/>', _sink);
      ++idx;
    }
    --_currentIdent;
    _writeTags(tags, _sink);
    _writeString('</relation>', _sink);
    return _nextId++;
  }

  bool _relationNeeded(_Way way) {
    assert(way.tags.isNotEmpty, "way must have tags $way");
    if (way.wayIds.length == 1 && way.outerWayIds.isEmpty) {
      return false;
    }
    if (way.wayIds.isEmpty && way.outerWayIds.length == 1) {
      return false;
    }
    // cover the case where we do not yet have written the ways to the file.
    if (way.nodes.length == 1 && way.outerNodes.isEmpty) {
      return false;
    }
    if (way.nodes.isEmpty && way.outerNodes.length == 1) {
      return false;
    }
    return true;
  }

  /// writes all ways from the list to a given sink. The sink may be a temporary file or the destination file. Stores ways which needs relations in a
  /// relation-list. Clears the way list.
  void _writeWays(IOSink sink) {
    for (var way in _ways) {
      List<int> wayIds = [];
      // the conditions are changing in the for loop, so check before
      bool relationNeeded = _relationNeeded(way);
      for (List<int> nodes in way.nodes) {
        wayIds.add(_writeWay(nodes, !relationNeeded ? way.tags : [], sink));
      }
      way.addWayIds(wayIds);
      wayIds.clear();
      for (List<int> nodes in way.outerNodes) {
        wayIds.add(_writeWay(nodes, !relationNeeded ? way.tags : [], sink));
      }
      way.addOuterWayIds(wayIds);
      way.nodes.clear();
      way.outerNodes.clear();
    }
    // remove if we have only one way and no outer way (we do not need a relation then)
    _ways.removeWhere((way) => !_relationNeeded(way));
    _relations.addAll(_ways);
    _ways.clear();
  }

  Future<void> _copyFileInChunks(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);

    final inputStream = sourceFile.openRead();

    await for (var buffer in inputStream) {
      _sink.add(buffer);
    }

    try {
      await sourceFile.delete();
    } catch (e) {
      // do nothing
    }
  }

  Future<void> close() async {
    if (_tempSink != null) {
      await _tempSink!.flush();
      await _tempSink!.close();
      _tempSink = null;
      await _copyFileInChunks(tempFilename);
    }
    _writeWays(_sink);
    for (var way in _relations) {
      _writeRelation(way.wayIds, way.outerWayIds, way.tags);
    }
    _relations.clear();
    --_currentIdent;
    _writeString('</osm>', _sink);
    await _sink.flush();
    await _sink.close();
  }

  void _writeString(String value, IOSink sink) {
    sink.add("".padLeft(_currentIdent, '  ').codeUnits);
    var utf8List = utf8.encoder.convert(value);
    sink.add(utf8List);
    sink.add("\n".codeUnits);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Way {
  final List<List<int>> nodes = [];

  final List<List<int>> outerNodes = [];

  final List<Tag> tags;

  /// The ids of the ways for this relation. The first way is the master, all others should be inner ways
  List<int> wayIds = [];

  /// The ids of other ways that are outer ways. They share the tags but have different ways.
  List<int> outerWayIds = [];

  _Way(this.tags);

  void addNodes(List<int> nodes) {
    this.nodes.add(nodes);
  }

  void addOuterNodes(List<int> nodes) {
    outerNodes.add(nodes);
  }

  void addWayIds(List<int> wayIds) {
    this.wayIds.addAll(wayIds);
  }

  void addOuterWayIds(List<int> wayIds) {
    outerWayIds.addAll(wayIds);
  }

  @override
  String toString() {
    return '_Way{nodes: $nodes, outerNodes: $outerNodes, tags: $tags, wayIds: $wayIds, outerWayIds: $outerWayIds}';
  }
}
