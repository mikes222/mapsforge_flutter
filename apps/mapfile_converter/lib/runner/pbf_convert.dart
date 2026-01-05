import 'dart:collection';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/filter/rendertheme_filter.dart';
import 'package:mapfile_converter/modifiers/custom_osm_primitive_modifier.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/holder_collection_file_implementation.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
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

    HolderCollectionFactory().setImplementation(HolderCollectionFileImplementation(10000));

    IPoiholderCollection osmNodes = HolderCollectionFactory().createPoiholderCollection("convert");
    WayholderFileCollection ways = WayholderFileCollection(
      filename: "convert_ways_${HolderCollectionFactory.randomId}.tmp",
    ); //HolderCollectionFactory().createWayholderCollection("convert");

    for (var sourcefile in sourcefiles) {
      _log.info("Reading $sourcefile, please wait...");
      if (sourcefile.toLowerCase().endsWith(".osm")) {
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readOsmFile(sourcefile, converter, maxGapMeter: maxgap, finalBoundingBox: finalBoundingBox, quiet: quiet);

        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!quiet) pbfAnalyzer.statistics();
        await osmNodes.mergeFrom(pbfAnalyzer.nodes);
        await ways.mergeFrom(pbfAnalyzer.ways());
        ways.addAll(pbfAnalyzer.waysMerged);
        await pbfAnalyzer.clear();
      } else {
        /// Read and analyze PBF file
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readFile(sourcefile, converter, maxGapMeter: maxgap, finalBoundingBox: finalBoundingBox, quiet: quiet);

        /// Now start exporting the data to a mapfile
        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!quiet) pbfAnalyzer.statistics();
        await osmNodes.mergeFrom(pbfAnalyzer.nodes);
        await ways.mergeFrom(pbfAnalyzer.ways());
        ways.addAll(pbfAnalyzer.waysMerged);
        await pbfAnalyzer.clear();
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
    // for (var entry in wayZoomlevels.entries) {
    //   IWayholderCollection wayholderCollection = entry.value;
    //   await wayholderCollection.forEach((wayholder) {
    //     if (wayholder.hasTag("railway")) print("checking ${wayholder.toStringWithoutNames()}");
    //   });
    // }
    await ways.dispose();
    renderTheme?.dispose();

    _log.info("Writing $destinationfile");
    if (destinationfile.toLowerCase().endsWith(".osm")) {
      OsmWriter osmWriter = OsmWriter(destinationfile, finalBoundingBox!);
      for (IPoiholderCollection pois2 in poiZoomlevels.values) {
        await pois2.forEach((Poiholder poiholder) {
          osmWriter.writeNode(poiholder.position, poiholder.tagholderCollection);
        });
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        await wayholders.forEach((Wayholder wayholder) {
          osmWriter.writeWay(wayholder);
        });
      }
      wayZoomlevels.clear();
      await osmWriter.close();
    } else if (destinationfile.toLowerCase().endsWith(".pbf")) {
      PbfWriter pbfWriter = PbfWriter(destinationfile, finalBoundingBox!);
      for (IPoiholderCollection poiholderCollection in poiZoomlevels.values) {
        await poiholderCollection.forEach((Poiholder poiholder) async {
          await pbfWriter.writeNode(poiholder.position, poiholder.tagholderCollection);
        });
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        await wayholders.forEach((Wayholder wayholder) async {
          await pbfWriter.writeWay(wayholder);
        });
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
      TagholderModel model = TagholderModel();

      List<Subfile> subfiles = [];
      for (int zoomlevel in zoomlevels) {
        if (previousZoomlevel != null) {
          ZoomlevelRange zoomlevelRange = ZoomlevelRange(previousZoomlevel, zoomlevel == zoomlevels.last ? zoomlevel : zoomlevel - 1);

          PoiWayCollections poiWayCollections = await _fillSubfile(
            mapHeaderInfo.tilePixelSize,
            poiZoomlevels,
            wayZoomlevels,
            mapHeaderInfo.boundingBox,
            maxDeviation,
            zoomlevelRange,
            model,
          );
          Subfile subfile = Subfile(
            mapHeaderInfo: mapHeaderInfo,
            baseZoomLevel: zoomlevelRange.zoomlevelMin,
            zoomlevelRange: zoomlevelRange,
            poiWayCollections: poiWayCollections,
            model: model,
          );

          subfiles.add(subfile);
          if (!quiet) await subfile.statistics();
        }
        previousZoomlevel = zoomlevel;
      }

      model.setPoiIndexes();
      model.setWayIndexes();
      MapfileWriter mapfileWriter = MapfileWriter(filename: destinationfile, mapHeaderInfo: mapHeaderInfo, subfiles: subfiles, model: model);

      /// Write everything to the file and close the file
      await mapfileWriter.write(maxDeviation, isolates);
      await mapfileWriter.close();

      for (var poiholderCollection in poiZoomlevels.values) {
        await poiholderCollection.dispose();
      }
      poiZoomlevels.clear();
      for (var wayholderCollection in wayZoomlevels.values) {
        await wayholderCollection.dispose();
      }
      wayZoomlevels.clear();
    }
    _log.info("Completed");
  }

  Future<PoiWayCollections> _fillSubfile(
    int tilePixelSize,
    Map<ZoomlevelRange, IPoiholderCollection> poiZoomlevels,
    Map<ZoomlevelRange, IWayholderCollection> wayZoomlevels,
    BoundingBox boundingBox,
    double maxDeviationSize,
    ZoomlevelRange subfileZoomlevelRange,
    TagholderModel model,
  ) async {
    PoiWayCollections poiWayCollections = PoiWayCollections();
    for (int zoomlevel = subfileZoomlevelRange.zoomlevelMin; zoomlevel <= subfileZoomlevelRange.zoomlevelMax; ++zoomlevel) {
      poiWayCollections.poiholderCollections[zoomlevel] = HolderCollectionFactory().createPoiholderCollection("subfile_$zoomlevel");
      poiWayCollections.wayholderCollections[zoomlevel] = HolderCollectionFactory().createWayholderCollection("subfile_$zoomlevel");
    }

    for (var entry in poiZoomlevels.entries) {
      ZoomlevelRange zoomlevelRange = entry.key;
      IPoiholderCollection poiholderCollection = entry.value;
      if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) continue;
      if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) continue;
      IPoiholderCollection resultPoiholderCollection =
          poiWayCollections.poiholderCollections[max(subfileZoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
      await poiholderCollection.forEach((poiholder) {
        // print(poiholder.toStringWithoutNames());
        // model.debug();
        poiholder.tagholderCollection.connectPoiToModel(model);
        resultPoiholderCollection.add(poiholder);
      });
      //await poiWayCollections.poiholderCollections[max(subfileZoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!.mergeFrom(poiholderCollection);
    }
    ISubfileFiller subfileFiller = await IsolateSubfileFiller.create(
      subfileZoomlevelRange: subfileZoomlevelRange,
      boundingBox: boundingBox,
      maxDeviation: maxDeviationSize,
    );
    //    ISubfileFiller subfileFiller = SubfileFiller(subfile.zoomlevelRange, maxDeviationSize, boundingBox);
    List<Future> wayholderFutures = [];
    for (var entry in wayZoomlevels.entries) {
      ZoomlevelRange zoomlevelRange = entry.key;
      IWayholderCollection wayholderCollection = entry.value;
      if (wayholderCollection.isEmpty) continue;
      if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) continue;
      if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) continue;
      IWayholderCollection resultWayholderCollection =
          poiWayCollections.wayholderCollections[max(subfileZoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
      //    print("create $zoomlevelRange with ${wayholderlist.count} ways for ${subfile.zoomlevelRange}");
      wayholderFutures.add(_isolate(resultWayholderCollection, zoomlevelRange, wayholderCollection, subfileFiller, model));
      if (wayholderFutures.length >= 20) {
        await Future.wait(wayholderFutures);
        wayholderFutures.clear();
      }
    }
    await Future.wait(wayholderFutures);
    return poiWayCollections;
  }

  Future<void> _isolate(
    IWayholderCollection resultWayholderCollection,
    ZoomlevelRange zoomlevelRange,
    IWayholderCollection wayholderlist,
    ISubfileFiller subfileFiller,
    TagholderModel model,
  ) async {
    // we create deep clones of wayholders because of isolates. This prevents problems later when reducing waypoints for different zoomlevels.
    // Do NOT remove the isolate code without further examination!
    List<Wayholder> wayholders = await subfileFiller.prepareWays(wayholderlist);
    for (var wayholder in wayholders) {
      wayholder.tagholderCollection.connectWayToModel(model);
    }
    resultWayholderCollection.addAll(wayholders);
  }
}
