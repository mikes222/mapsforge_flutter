import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/mapfile/subfile_creator.dart';
import 'package:mapfile_converter/modifiers/custom_osm_primitive_modifier.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/modifiers/poiholder_file_collection.dart';
import 'package:mapfile_converter/modifiers/rendertheme_filter.dart';
import 'package:mapfile_converter/modifiers/wayholder_file_collection.dart';
import 'package:mapfile_converter/osm/osm_writer.dart';
import 'package:mapfile_converter/pbf/pbf_writer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class PbfConvert {
  final _log = Logger('PbfConvert');

  Future<void> convert({
    required List<int> zoomlevels,
    String? renderthemeFile,
    BoundingBox? finalBoundingBox,
    required List<String> sourcefiles,
    required double maxgap,
    required bool quiet,
    required bool debug,
    required String destinationfile,
    required String languagePreference,
    required double maxDeviation,
    required int isolates,
  }) async {
    DefaultOsmPrimitiveConverter converter = DefaultOsmPrimitiveConverter();
    Rendertheme? renderTheme;

    if (renderthemeFile != null) {
      renderTheme = await RenderThemeBuilder.createFromFile(renderthemeFile);
      RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
      for (Rule rule in renderTheme.rulesList) {
        ruleAnalyzer.apply(rule);
      }

      converter = CustomOsmPrimitiveConverter(
        allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
        allowedWayTags: ruleAnalyzer.wayValueinfos(),
        negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
        negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
        keys: ruleAnalyzer.keys,
      );
    }

    PoiholderFileCollection osmNodes = PoiholderFileCollection(
      filename: "convert_nodes_${DateTime.timestamp().millisecondsSinceEpoch}.tmp",
      spillBatchSize: 1000000,
    );
    WayholderFileCollection ways = WayholderFileCollection(filename: "convert_ways_${DateTime.timestamp().millisecondsSinceEpoch}.tmp");

    for (var sourcefile in sourcefiles) {
      _log.info("Reading $sourcefile, please wait...");
      if (sourcefile.toLowerCase().endsWith(".osm")) {
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readOsmFile(sourcefile, converter, maxGapMeter: maxgap, finalBoundingBox: finalBoundingBox, quiet: quiet);

        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!quiet) pbfAnalyzer.statistics();
        await osmNodes.mergeFrom(pbfAnalyzer.nodes);
        await ways.mergeFrom(pbfAnalyzer.ways());
        ways.addAll(pbfAnalyzer.waysMerged);
        pbfAnalyzer.clear();
      } else {
        /// Read and analyze PBF file
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readFile(sourcefile, converter, maxGapMeter: maxgap, finalBoundingBox: finalBoundingBox, quiet: quiet);

        /// Now start exporting the data to a mapfile
        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!quiet) pbfAnalyzer.statistics();
        await osmNodes.mergeFrom(pbfAnalyzer.nodes);
        await ways.mergeFrom(pbfAnalyzer.ways());
        ways.addAll(pbfAnalyzer.waysMerged);
        pbfAnalyzer.clear();
      }
    }

    /// Simplify the data: Remove small areas, simplify ways
    RenderthemeFilter renderthemeFilter = RenderthemeFilter();
    Map<ZoomlevelRange, IPoiholderCollection> poiZoomlevels = renderTheme != null
        ? await renderthemeFilter.filterNodes(osmNodes, renderTheme)
        : await renderthemeFilter.convertNodes(osmNodes);
    await osmNodes.dispose();
    Map<ZoomlevelRange, IWayholderCollection> wayZoomlevels = renderTheme != null
        ? await renderthemeFilter.filterWays(ways, renderTheme)
        : await renderthemeFilter.convertWays(ways);
    await ways.dispose();

    _log.info("Writing $destinationfile");
    if (destinationfile.toLowerCase().endsWith(".osm")) {
      OsmWriter osmWriter = OsmWriter(destinationfile, finalBoundingBox!);
      for (IPoiholderCollection pois2 in poiZoomlevels.values) {
        for (Poiholder poi in await pois2.getAll()) {
          osmWriter.writeNode(poi.position, poi.tagholderCollection);
        }
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        for (Wayholder wayholder in await wayholders.getAll()) {
          osmWriter.writeWay(wayholder);
        }
      }
      wayZoomlevels.clear();
      await osmWriter.close();
    } else if (destinationfile.toLowerCase().endsWith(".pbf")) {
      PbfWriter pbfWriter = PbfWriter(destinationfile, finalBoundingBox!);
      for (IPoiholderCollection pois2 in poiZoomlevels.values) {
        for (Poiholder poi in await pois2.getAll()) {
          await pbfWriter.writeNode(poi.position, poi.tagholderCollection);
        }
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        for (Wayholder wayholder in await wayholders.getAll()) {
          await pbfWriter.writeWay(wayholder);
        }
      }
      wayZoomlevels.clear();
      await pbfWriter.close();
    } else {
      poiZoomlevels.removeWhere((key, value) => key.zoomlevelMin > zoomlevels.last || key.zoomlevelMax < zoomlevels.first);
      wayZoomlevels.removeWhere((key, value) => key.zoomlevelMin > zoomlevels.last || key.zoomlevelMax < zoomlevels.first);
      if (!quiet) {
        SplayTreeMap treeMap = SplayTreeMap.from(poiZoomlevels, (a, b) => a.zoomlevelMin.compareTo(b.zoomlevelMin));
        treeMap.forEach((zoomlevelRange, nodelist) {
          _log.info("Nodes: ZoomlevelRange: $zoomlevelRange, ${nodelist.length}");
        });
        treeMap = SplayTreeMap.from(wayZoomlevels, (a, b) => a.zoomlevelMin.compareTo(b.zoomlevelMin));
        treeMap.forEach((zoomlevelRange, waylist) {
          _log.info("Ways: ZoomlevelRange: $zoomlevelRange, ${waylist.length}");
        });
      }

      MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
        boundingBox: finalBoundingBox!,
        debugFile: debug,
        zoomlevelRange: ZoomlevelRange(zoomlevels.first, zoomlevels.last),
        languagesPreference: languagePreference == "" ? null : languagePreference,
      );

      /// Create the zoomlevels in the mapfile
      int? previousZoomlevel;
      SubfileCreator subfileCreator = SubfileCreator(maxDeviation);
      List<Subfile> subfiles = [];
      for (int zoomlevel in zoomlevels) {
        if (previousZoomlevel != null) {
          Subfile subfile = await subfileCreator.createSubfile(
            mapHeaderInfo,
            previousZoomlevel,
            zoomlevel == zoomlevels.last ? zoomlevel : zoomlevel - 1,
            wayZoomlevels,
            poiZoomlevels,
          );
          subfiles.add(subfile);
          if (!quiet) await subfile.statistics();
        }
        previousZoomlevel = zoomlevel;
      }

      TagholderModel model = TagholderModel();
      MapfileWriter mapfileWriter = MapfileWriter(filename: destinationfile, mapHeaderInfo: mapHeaderInfo, subfiles: subfiles, model: model);

      /// Write everything to the file and close the file
      await mapfileWriter.write(maxDeviation, isolates);
      await mapfileWriter.close();

      for (var poiholderCollection in poiZoomlevels.values) {
        poiholderCollection.dispose();
      }
      poiZoomlevels.clear();
      for (var wayholderCollection in wayZoomlevels.values) {
        await wayholderCollection.dispose();
      }
      wayZoomlevels.clear();
    }
  }
}
