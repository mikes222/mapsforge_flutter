import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

class PbfStatistics {
  final _log = Logger('PbfStatistics');

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  final Map<int, PointOfInterest> _nodeHolders = {};

  final Map<int, StatsWayholder> _wayHolders = {};

  final Map<int, StatsRelation> _relations = {};

  final Map<String, _Tagholder> _nodeTags = {};

  final Map<String, _Tagholder> _wayTags = {};

  final Map<String, _Tagholder> _relationTags = {};

  int nodeNotFound = 0;

  int wayNotFound = 0;

  int wayTooLessNodes = 0;

  int wayNoTag = 0;

  int relationNoTags = 0;

  BoundingBox? boundingBox;

  static Future<PbfStatistics> readFile(String filename) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    PbfStatistics statistics = await readSource(readbufferSource);
    readbufferSource.dispose();
    return statistics;
  }

  static Future<PbfStatistics> readSource(ReadbufferSource readbufferSource) async {
    int sourceLength = await readbufferSource.length();
    PbfStatistics pbfStatistics = PbfStatistics();
    await pbfStatistics.readToMemory(readbufferSource, sourceLength);
    return pbfStatistics;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader(readbufferSource: readbufferSource, sourceLength: sourceLength);
    while (true) {
      OsmData? blockData = await pbfReader.readBlobData();
      if (blockData == null) break;
      await _analyze1Block(blockData);
    }
    boundingBox = pbfReader.calculateBounds();
    analyze();
  }

  void analyze() {
    _relations.forEach((id, relationHolder) {
      for (var member in relationHolder.osmRelation.members) {
        switch (member.memberType) {
          case MemberType.node:
            if (!_nodeHolders.containsKey(member.memberId)) {
              ++nodeNotFound;
            }
            break;
          case MemberType.way:
            StatsWayholder? wayholder = _wayHolders[member.memberId];
            if (wayholder == null) {
              relationHolder.wayNotFound++;
              ++wayNotFound;
            } else {
              relationHolder.nodesNotFound += wayholder.nodesNotFound;
              relationHolder.nodes += wayholder.way.refs.length;
            }
            break;
          case MemberType.relation:
            break;
        }
      }
    });
  }

  Future<void> _analyze1Block(OsmData blockData) async {
    _log.info(blockData);
    for (var osmNode in blockData.nodes) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      //print("node: ${pointOfInterest}");
      if (pointOfInterest != null) {
        assert(!_nodeHolders.containsKey(osmNode.id), "node already exists ${osmNode.id} -> ${_nodeHolders[osmNode.id]}");
        _nodeHolders[osmNode.id] = pointOfInterest;
        for (var tag in pointOfInterest.tags) {
          _increment(_nodeTags, tag, 1);
        }
      }
    }
    for (OsmWay osmWay in blockData.ways) {
      List<ILatLong> latLongs = [];
      int nodesNotFound = 0;
      for (var ref in osmWay.refs) {
        PointOfInterest? pointOfInterest = _searchPoi(ref);
        if (pointOfInterest != null) {
          latLongs.add(pointOfInterest.position);
        } else {
          ++nodeNotFound;
          ++nodesNotFound;
        }
      }
      assert(!_wayHolders.containsKey(osmWay.id));
      _wayHolders[osmWay.id] = StatsWayholder(osmWay, osmWay.refs.length, nodesNotFound);
      for (var tag in osmWay.tags.entries) {
        _increment(_wayTags, Tag(tag.key, tag.value), latLongs.length);
      }
      if (latLongs.length < 2) {
        ++wayTooLessNodes;
      }
    }
    for (var osmRelation in blockData.relations) {
      assert(!_relations.containsKey(osmRelation.id));
      _relations[osmRelation.id] = StatsRelation(osmRelation);
      Way? relationWay = converter.createMergedWay(osmRelation);
      if (relationWay != null) {
        for (var tag in relationWay.tags) {
          _increment(_relationTags, tag, 1);
        }
      } else {
        ++relationNoTags;
      }
    }
  }

  void _increment(Map<String, _Tagholder> tagholders, Tag tag, int items) {
    String tagkey = tag.key!;
    String tagvalue = tag.value!;
    if (tagkey == "name") {
      tagkey = "name";
      tagvalue = "*";
    }
    if (tagkey == "int_name") {
      tagkey = "int_name";
      tagvalue = "*";
    }
    if (tagkey == "loc_name") {
      tagkey = "loc_name";
      tagvalue = "*";
    }
    if (tagkey == "official_name") {
      tagkey = "official_name";
      tagvalue = "*";
    }
    if (tagkey.startsWith("name:")) {
      tagkey = "name:*";
      tagvalue = "*";
    }
    if (tagkey.startsWith("official_name:")) {
      tagkey = "official_name:*";
      tagvalue = "*";
    }
    if (tagkey == "ref") {
      tagkey = "ref";
      tagvalue = "*";
    }
    String key = "$tagkey=$tagvalue";
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
    _log.info(
      "$nodeNotFound nodes not found, $wayNotFound ways not found, $wayTooLessNodes ways have too less nodes, $wayNoTag ways without tags, $relationNoTags relations without tags",
    );
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation count: ${_relations.length}");
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

  void find(String? toFind) {
    if (toFind == null || toFind == "") return;
    List<String> v = toFind.split("=");
    String key = v[0];
    String? value = v.length == 2 ? v[1] : null;
    if (value == null) {
      _log.info("Searching for key $key");
    } else {
      _log.info("Searching for key $key and value $value");
    }

    List<PointOfInterest> nodes = _nodeHolders.values.where((test) => value != null ? test.hasTagValue(key, value) : test.hasTag(key)).toList();
    nodes.forEach((action) {
      _log.info("Found node ${action.toStringWithoutNames()}");
    });
    List<StatsWayholder> ways = _wayHolders.values.where((test) => value != null ? test.way.hasTagValue(key, value) : test.way.hasTag(key)).toList();
    ways.forEach((action) {
      _log.info("Found way ${action.toStringWithoutNames()}");
    });
    List<StatsRelation> relations =
        _relations.values.where((test) => value != null ? test.osmRelation.hasTagValue(key, value) : test.osmRelation.hasTag(key)).toList();
    relations.forEach((action) {
      _log.info("Found relation ${action.toStringWithoutNames()}");
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

  String toStringWithoutNames() {
    return "count: $count";
  }
}

//////////////////////////////////////////////////////////////////////////////

class StatsWayholder {
  final OsmWay way;

  final int originalNodeCount;

  final int nodesNotFound;

  StatsWayholder(this.way, this.originalNodeCount, this.nodesNotFound);

  String toStringWithoutNames() {
    return "way: ${way.toStringWithoutNames()}, nodeCount: $originalNodeCount, nodesNotFound: $nodesNotFound";
  }
}

//////////////////////////////////////////////////////////////////////////////

class StatsRelation {
  final OsmRelation osmRelation;

  int wayNotFound = 0;

  int nodesNotFound = 0;

  int nodes = 0;

  StatsRelation(this.osmRelation);

  String toStringWithoutNames() {
    return "relation: ${osmRelation.toStringWithoutNames()}, nodes: $nodes, wayNotFound: $wayNotFound, nodesNotFound: $nodesNotFound";
  }
}
