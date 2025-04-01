import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';

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

  void writeWay(Way way, List<Waypath> waypaths) {
    _Way _way = _Way(way.tags);
    way.latLongs.forEachIndexed((idx, latLongs) {
      List<int> nodes = [];
      for (var latLong in latLongs) {
        nodes.add(writeNode(latLong, []));
      }
      _way.addNodes(nodes);
    });
    for (var waypath in waypaths) {
      List<int> nodes = [];
      for (var latLong in waypath.path) {
        nodes.add(writeNode(latLong, []));
      }
      _way.addOuterNodes(nodes);
    }
    _ways.add(_way);
    if (_ways.length >= 1000) {
      _tempSink ??= File(tempFilename).openWrite();
      _writeWays(_tempSink!);
    }
  }

  void _writeTags(List<Tag> tags, IOSink sink) {
    ++_currentIdent;
    for (var tag in tags) {
      _writeString('<tag k="${tag.key}" v="${tag.value}"/>', sink);
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

  void _writeWays(IOSink sink) {
    for (var way in _ways) {
      List<int> wayIds = [];
      for (List<int> nodes in way.nodes) {
        wayIds.add(_writeWay(nodes, way.nodes.length == 1 && way.outerNodes.isEmpty ? way.tags : [], sink));
      }
      way.addWayIds(wayIds);
      wayIds.clear();
      for (List<int> nodes in way.outerNodes) {
        wayIds.add(_writeWay(nodes, [], sink));
      }
      way.addOuterWayIds(wayIds);
      way.nodes.clear();
      way.outerNodes.clear();
    }
    // remove if we have only one way and no outer way (we do not need a relation then)
    _ways.removeWhere((test) => test.wayIds.length == 1 && test.outerWayIds.isEmpty);
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

  List<int> wayIds = [];

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
}
