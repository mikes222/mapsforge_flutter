import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:xml/xml_events.dart';

import 'osm_data.dart';

class OsmReader implements IPbfReader {
  final _log = Logger('OsmReader');

  final Map<int, OsmNode> _nodes = {};
  final Map<int, OsmWay> _ways = {};
  final Map<int, OsmRelation> _relations = {};
  BoundingBox? boundingBox;

  OsmNode? _currentNode;
  OsmWay? _currentWay;
  OsmRelation? _currentRelation;

  late final Stream<XmlEvent> _stream;

  late final StreamIterator<XmlEvent> _iterator;

  OsmReader(String filePath) {
    final file = File(filePath);
    final inputStream = file.openRead();
    _stream = inputStream.transform(utf8.decoder).toXmlEvents().normalizeEvents().flatten();
    _iterator = StreamIterator<XmlEvent>(_stream);
  }

  @override
  void dispose() {
    _nodes.clear();
    _ways.clear();
    _relations.clear();
    _iterator.cancel();
  }

  @override
  Future<OsmData?> readBlobData(int position) async {
    return _readStream();
  }

  @override
  Future<OsmData?> readNextBlobData() {
    return _readStream();
  }

  Future<OsmData?> _readStream() async {
    while (await _iterator.moveNext()) {
      final event = _iterator.current;
      //print("event: ${event}");
      if (event is XmlStartElementEvent) {
        //print("  start element: ${element}");
        switch (event.name) {
          case 'node':
            _currentNode = OsmNode(
              id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value),
              tags: {},
              latLong: LatLong(
                double.parse(event.attributes.firstWhere((attr) => attr.name == 'lat').value),
                double.parse(event.attributes.firstWhere((attr) => attr.name == 'lon').value),
              ),
            );
            _nodes[_currentNode!.id] = _currentNode!;
            if (event.isSelfClosing) {
              _currentNode = null;
              OsmData? osmData = _sendData(false);
              if (osmData != null) return osmData;
            }
            break;
          case 'way':
            _currentWay = OsmWay(id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value), refs: [], tags: {});
            _ways[_currentWay!.id] = _currentWay!;
            if (event.isSelfClosing) {
              _currentWay = null;
              OsmData? osmData = _sendData(false);
              if (osmData != null) return osmData;
            }
            break;
          case 'relation':
            _currentRelation = OsmRelation(id: int.parse(event.attributes.firstWhere((attr) => attr.name == 'id').value), members: [], tags: {});
            _relations[_currentRelation!.id] = _currentRelation!;
            if (event.isSelfClosing) {
              _currentRelation = null;
              OsmData? osmData = _sendData(false);
              if (osmData != null) return osmData;
            }
            break;
          case 'tag':
            if (_currentNode != null) {
              _currentNode!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] = event.attributes.firstWhere((attr) => attr.name == 'v').value;
            } else if (_currentWay != null) {
              _currentWay!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] = event.attributes.firstWhere((attr) => attr.name == 'v').value;
            } else if (_currentRelation != null) {
              _currentRelation!.tags[event.attributes.firstWhere((attr) => attr.name == 'k').value] = event.attributes
                  .firstWhere((attr) => attr.name == 'v')
                  .value;
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
            OsmData? osmData = _sendData(false);
            if (osmData != null) return osmData;
            break;
          case 'way':
            _currentWay = null;
            OsmData? osmData = _sendData(false);
            if (osmData != null) return osmData;
            break;
          case 'relation':
            _currentRelation = null;
            OsmData? osmData = _sendData(false);
            if (osmData != null) return osmData;
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
    OsmData? osmData = _sendData(true);
    return osmData;
  }

  OsmData? _sendData(bool force) {
    if (force && _nodes.isEmpty && _ways.isEmpty && _relations.isEmpty) {
      return null;
    }
    if (force || _nodes.length >= 1000000 || _ways.length >= 100000 || _relations.length >= 1000) {
      //print("callback: ${nodes.length} ${ways.length} ${relations.length}");
      final osmData = OsmData(nodes: _nodes.values.toList(), ways: _ways.values.toList(), relations: _relations.values.toList());
      _nodes.clear();
      _ways.clear();
      _relations.clear();
      return osmData;
    }
    return null;
  }

  @override
  Future<BoundingBox?> calculateBounds() async {
    return boundingBox;
  }

  @override
  Future<List<int>> getBlobPositions() {
    throw UnimplementedError();
  }
}
