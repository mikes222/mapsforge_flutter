import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:xml/xml_events.dart';

import 'osm_data.dart';

class OsmReader {
  final _log = Logger('OsmReader');

  final Map<int, OsmNode> _nodes = {};
  final Map<int, OsmWay> _ways = {};
  final Map<int, OsmRelation> _relations = {};
  BoundingBox? boundingBox;

  OsmNode? _currentNode;
  OsmWay? _currentWay;
  OsmRelation? _currentRelation;

  late final Stream _events;

  OsmReader(String filePath) {
    final file = File(filePath);
    final inputStream = file.openRead();
    _events = inputStream.transform(utf8.decoder).toXmlEvents().normalizeEvents().flatten();
  }

  Future<void> readOsmFile(Function(OsmData) callback) async {
    await _readStream(callback);
  }

  Future<void> _readStream(Function(OsmData) callback) async {
    await for (final event in _events) {
      //print("event: ${event}");
      if (event is XmlStartElementEvent) {
        //print("  start element: ${element}");
        switch (event.name) {
          case 'node':
            _currentNode = OsmNode(
              id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value),
              tags: {},
              latitude: double.parse(event.attributes.firstWhere((attr) => attr.name == 'lat').value),
              longitude: double.parse(event.attributes.firstWhere((attr) => attr.name == 'lon').value),
            );
            _nodes[_currentNode!.id] = _currentNode!;
            if (event.isSelfClosing) {
              _currentNode = null;
              _sendData(callback, false);
            }
            break;
          case 'way':
            _currentWay = OsmWay(id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value), refs: [], tags: {});
            _ways[_currentWay!.id] = _currentWay!;
            if (event.isSelfClosing) {
              _currentWay = null;
              _sendData(callback, false);
            }
            break;
          case 'relation':
            _currentRelation = OsmRelation(id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value), members: [], tags: {});
            _relations[_currentRelation!.id] = _currentRelation!;
            if (event.isSelfClosing) {
              _currentRelation = null;
              _sendData(callback, false);
            }
            break;
          case 'tag':
            if (_currentNode != null) {
              _currentNode!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] = event.attributes.firstWhere((attr) => attr.name == 'v').value;
            } else if (_currentWay != null) {
              _currentWay!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] = event.attributes.firstWhere((attr) => attr.name == 'v').value;
            } else if (_currentRelation != null) {
              _currentRelation!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] =
                  event.attributes.firstWhere((attr) => attr.name == 'v').value;
            }
            break;
          case 'nd':
            if (_currentWay != null) {
              _currentWay!.refs.add(int.parse(event.attributes.firstWhere((attr) => attr.name == 'ref').value));
            }
            break;
          case 'member':
            if (_currentRelation != null) {
              _currentRelation!.members.add(
                OsmRelationMember(
                  memberType: MemberType.values.firstWhere((test) => test.name.contains(event.attributes.firstWhere((attr) => attr.name == 'type').value)),
                  memberId: int.parse(event.attributes.firstWhere((attr) => attr.name == 'ref').value),
                  role: event.attributes.firstWhere((attr) => attr.name == 'role').value,
                ),
              );
            }
            break;
          case 'bounds':
            boundingBox = BoundingBox(
              double.parse(event.attributes.firstWhere((attr) => attr.name == 'minlat').value),
              double.parse(event.attributes.firstWhere((attr) => attr.name == 'minlon').value),
              double.parse(event.attributes.firstWhere((attr) => attr.name == 'maxlat').value),
              double.parse(event.attributes.firstWhere((attr) => attr.name == 'maxlon').value),
            );
            break;
        }
      } else if (event is XmlEndElementEvent) {
        //print("  end element: ${element}");
        switch (event.name) {
          case 'node':
            _currentNode = null;
            _sendData(callback, false);
            break;
          case 'way':
            _currentWay = null;
            _sendData(callback, false);
            break;
          case 'relation':
            _currentRelation = null;
            _sendData(callback, false);
            break;
          case 'tag':
            break;
        }
      } else if (event is XmlTextEvent) {
      } else if (event is XmlDeclarationEvent) {
      } else {
        _log.info("unsupported element: ${event} ${event.runtimeType}");
      }
    }
    _sendData(callback, true);
  }

  void _sendData(Function(OsmData) callback, bool force) {
    if (force || _nodes.length >= 1000000 || _ways.length >= 100000 || _relations.length >= 1000) {
      //print("callback: ${nodes.length} ${ways.length} ${relations.length}");
      final pbfData = OsmData(nodes: _nodes.values.toList(), ways: _ways.values.toList(), relations: _relations.values.toList());
      _nodes.clear();
      _ways.clear();
      _relations.clear();
      callback(pbfData);
    }
  }
}
