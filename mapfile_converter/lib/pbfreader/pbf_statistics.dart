import 'package:logging/logging.dart';
import 'package:mapfile_converter/pbfreader/pbf_analyzer.dart';
import 'package:mapfile_converter/pbfreader/pbf_data.dart';
import 'package:mapfile_converter/pbfreader/pbf_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

class PbfStatistics {
  final _log = Logger('PbfStatistics');

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  final Map<int, PointOfInterest> _nodeHolders = {};

  final Map<int, Wayholder> _wayHolders = {};

  Map<int, OsmRelation> relations = {};

  Map<String, _Tagholder> _nodeTags = {};

  Map<String, _Tagholder> _wayTags = {};

  Map<String, _Tagholder> _relationTags = {};

  BoundingBox? boundingBox;

  static Future<PbfStatistics> readFile(String filename) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    return readSource(readbufferSource);
  }

  static Future<PbfStatistics> readSource(ReadbufferSource readbufferSource) async {
    int sourceLength = await readbufferSource.length();
    PbfStatistics pbfStatistics = PbfStatistics();
    pbfStatistics.readToMemory(readbufferSource, sourceLength);
    return pbfStatistics;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
      PbfData blockData = await pbfReader.readBlobData(readbufferSource);
      await _analyze1Block(blockData);
    }
    boundingBox = pbfReader.calculateBounds();
  }

  Future<void> _analyze1Block(PbfData blockData) async {
    //print(blockData);
    blockData.nodes.forEach((osmNode) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null) {
        _nodeHolders[osmNode.id] = pointOfInterest;
        pointOfInterest.tags.forEach((Tag tag) {
          increment(_nodeTags, tag, 1);
        });
      }
    });
    blockData.ways.forEach((osmWay) {
      List<List<ILatLong>> latLongs = [];
      latLongs.add([]);
      osmWay.refs.forEach((ref) {
        PointOfInterest? pointOfInterest = _searchPoi(ref);
        if (pointOfInterest != null) {
          latLongs[0].add(pointOfInterest.position);
        }
      });
      if (latLongs[0].length >= 2) {
        Way? way = converter.createWay(osmWay, latLongs);
        if (way != null) {
          _wayHolders[osmWay.id] = Wayholder.fromWay(way);
          way.tags.forEach((Tag tag) {
            increment(_wayTags, tag, latLongs[0].length);
          });
        }
      }
    });
    blockData.relations.forEach((osmRelation) {
      relations[osmRelation.id] = osmRelation;
      Way? relationWay = converter.createMergedWay(osmRelation);
      if (relationWay != null) {
        relationWay.tags.forEach((Tag tag) {
          increment(_relationTags, tag, 1);
        });
      }
    });
  }

  void increment(Map<String, _Tagholder> tagholders, Tag tag, int items) {
    String key = "${tag.key!}=${tag.value}";
    if (!tagholders.containsKey(key)) {
      tagholders[key] = _Tagholder(key);
    }
    tagholders[key]!.count++;
    tagholders[key]!.items += items;
  }

  PointOfInterest? _searchPoi(int id) {
    PointOfInterest? poi = _nodeHolders[id];
    if (poi != null) {
      return poi;
    }
    return null;
  }

  void statistics() {
    if (boundingBox != null) {
      _log.info(boundingBox);
    }
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation count: ${relations.length}");
    List<_Tagholder> tagholders = _nodeTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for nodes:"));
    tagholders.take(20).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count}");
    });

    tagholders = _wayTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for ways:"));
    tagholders.take(20).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count} with ${(tagholder.items / tagholder.count).toStringAsFixed(1)} items per way");
    });

    tagholders = _relationTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for relations:"));
    tagholders.take(20).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count}");
    });
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Tagholder {
  int count = 0;

  int items = 0;

  final String key;

  _Tagholder(this.key);

  @override
  String toString() {
    return "count: $count";
  }
}
