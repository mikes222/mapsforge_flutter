import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class PbfStatistics {
  final _log = Logger('PbfStatistics');

  final DefaultOsmPrimitiveConverter converter;

  final Map<String, _Tagholder> _nodeTags = {};

  final Map<String, _Tagholder> _wayTags = {};

  final Map<String, _Tagholder> _relationTags = {};

  final int spillBatchSize;

  late PbfAnalyzer pbfAnalyzer;

  PbfStatistics(this.converter, this.spillBatchSize);

  Future<PbfAnalyzer> readFile(String sourcefile) async {
    ReadbufferSource readbufferSource = createReadbufferSource(sourcefile);
    int sourceLength = await readbufferSource.length();
    IPbfReader pbfReader = await IsolatePbfReader.create(readbufferSource: readbufferSource, sourceLength: sourceLength);
    pbfAnalyzer = await PbfAnalyzer.readSource(
      converter,
      //finalBoundingBox: finalBoundingBox,
      quiet: false,
      spillBatchSize: spillBatchSize,
      pbfReader: pbfReader,
      length: sourceLength,
    );
    return pbfAnalyzer;
  }

  Future<void> analyze() async {
    await pbfAnalyzer.mergeRelationsToWays(null);
    await pbfAnalyzer.nodes.forEach((nodeholder) {
      _increment(_nodeTags, nodeholder.tagholderCollection, 1);
    });
    await pbfAnalyzer.ways.forEach((key, wayholder) {
      _increment(_wayTags, wayholder.tagholderCollection, wayholder.nodeCount());
    });
    for (var osmRelation in pbfAnalyzer.waysMerged) {
      _increment(_relationTags, osmRelation.tagholderCollection, 1);
    }
  }

  void _increment(Map<String, _Tagholder> tagholders, TagholderCollection tagholderCollection, int items) {
    for (var tag in tagholderCollection.tagholders) {
      String tagkey = tag.key;
      String tagvalue = tag.value;
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
      if (tagkey.startsWith("addr:housenumber")) {
        tagkey = "addr:housenumber";
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
  }

  void statistics() {
    pbfAnalyzer.statistics();
    List<_Tagholder> tagholders = _nodeTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for nodes (${tagholders.length}):"));
    tagholders.take(40).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count}");
    });

    tagholders = _wayTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for ways (${tagholders.length}):"));
    tagholders.take(40).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count} with ${(tagholder.items / tagholder.count).toStringAsFixed(1)} items per way");
    });

    tagholders = _relationTags.values.toList();
    tagholders.sort((a, b) => b.count.compareTo(a.count));
    _log.info(("Most used Tags for relations (${tagholders.length}):"));
    tagholders.take(40).forEach((tagholder) {
      _log.info("  ${tagholder.key}: ${tagholder.count}");
    });
  }

  Future<void> find(String? toFind) async {
    if (toFind == null || toFind == "") return;
    List<String> v = toFind.split("=");
    String key = v[0];
    String? value = v.length == 2 ? v[1] : null;
    if (value == null) {
      _log.info("Searching for key $key");
    } else {
      _log.info("Searching for key $key and value $value");
    }

    List<Poiholder> nodes = [];
    await pbfAnalyzer.nodes.forEach((node) {
      if (value != null ? node.tagholderCollection.hasTagValue(key, value) : node.tagholderCollection.hasTag(key)) nodes.add(node);
    });
    for (Poiholder action in nodes) {
      _log.info("Found node ${action.toStringWithoutNames()}");
    }
    List<Wayholder> ways = [];
    await pbfAnalyzer.ways.forEach((id, node) {
      if (value != null ? node.tagholderCollection.hasTagValue(key, value) : node.tagholderCollection.hasTag(key)) ways.add(node);
    });
    for (var action in ways) {
      _log.info("Found way ${action.toStringWithoutNames()}");
    }
    List<OsmRelation> relations = pbfAnalyzer.relations.where((test) => value != null ? test.hasTagValue(key, value) : test.hasTag(key)).toList();
    for (var action in relations) {
      _log.info("Found relation ${action.toStringWithoutNames()}");
    }
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
