import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_cropper.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';

import '../testassetbundle.dart';
import '../testhelper.dart';

main() async {
  final _log = new Logger('CopyPbfToMapfileTest');

  testWidgets("Test monaco casino south part cropping for a tile", (WidgetTester tester) async {
    _initLogging();

    MemoryDatastore datastore = MemoryDatastore();
    // this is the casino in monaco
    List<ILatLong> points = [
      const LatLong(43.727158, 7.414372),
      const LatLong(43.727378, 7.414080), // 01, clockwise outside
      const LatLong(43.727467, 7.414211),
      const LatLong(43.727551, 7.414116),
      const LatLong(43.727645, 7.414247),
      const LatLong(43.727617, 7.414285),
      const LatLong(43.727654, 7.414335),
      const LatLong(43.727808, 7.414543),
      const LatLong(43.727849, 7.414482),
      const LatLong(43.728338, 7.415164),
      const LatLong(43.728312, 7.415199),
      const LatLong(43.728402, 7.415331),
      const LatLong(43.728383, 7.415358),
      const LatLong(43.728484, 7.415494),
      const LatLong(43.728451, 7.415547),
      const LatLong(43.728573, 7.415706),
      const LatLong(43.728516, 7.415789),
      const LatLong(43.728529, 7.415986),
      const LatLong(43.728463, 7.416073),
      const LatLong(43.728510, 7.416148),
      const LatLong(43.728368, 7.416331),
      const LatLong(43.728386, 7.416364),
      const LatLong(43.728181, 7.416634),
      const LatLong(43.728164, 7.416614),
      const LatLong(43.728028, 7.416811),
      const LatLong(43.727979, 7.416734),
      const LatLong(43.727899, 7.416854),
      const LatLong(43.727873, 7.416826),
      const LatLong(43.727774, 7.416828),
      const LatLong(43.727727, 7.416877),
      const LatLong(43.727646, 7.416765),
      const LatLong(43.727618, 7.416795),
      const LatLong(43.727593, 7.416793),
      const LatLong(43.727592, 7.416751),
      const LatLong(43.727551, 7.416791),
      const LatLong(43.727457, 7.416655),
      const LatLong(43.727427, 7.416696),
      const LatLong(43.726855, 7.415893),
      const LatLong(43.726840, 7.415912), // 38, clockwise <-- too early
      const LatLong(43.726727, 7.415749),
      const LatLong(43.726760, 7.415701),
      const LatLong(43.726671, 7.415574),
      const LatLong(43.726695, 7.415537),
      const LatLong(43.726666, 7.415498),
      const LatLong(43.726627, 7.415550),
      const LatLong(43.726533, 7.415411),
      const LatLong(43.726602, 7.415321),
      const LatLong(43.726553, 7.415250),
      const LatLong(43.726632, 7.415146),
      const LatLong(43.726612, 7.415111),
      const LatLong(43.726723, 7.414970),
      const LatLong(43.726882, 7.415167),
      const LatLong(43.726934, 7.415235),
      const LatLong(43.726899, 7.415283),
      const LatLong(43.726998, 7.415418),
      const LatLong(43.726965, 7.415460),
      const LatLong(43.727643, 7.416386),
      const LatLong(43.727686, 7.416335),
      const LatLong(43.727780, 7.416469),
      const LatLong(43.727812, 7.416431),
      const LatLong(43.727868, 7.416455),
      const LatLong(43.727963, 7.416324),
      const LatLong(43.727978, 7.416346),
      const LatLong(43.728161, 7.416091),
      const LatLong(43.728147, 7.416067),
      const LatLong(43.728242, 7.415941),
      const LatLong(43.728203, 7.415887),
      const LatLong(43.728236, 7.415839),
      const LatLong(43.728143, 7.415707),
      const LatLong(43.728172, 7.415670),
      const LatLong(43.727486, 7.414718),
      const LatLong(43.727457, 7.414760),
      const LatLong(43.727362, 7.414634),
      const LatLong(43.727331, 7.414680),
      const LatLong(43.727264, 7.414591),
      const LatLong(43.727222, 7.414535),
      const LatLong(43.727250, 7.414498),
      const LatLong(43.727158, 7.414372),
    ];
    Way way = Way(0, [const Tag("building", "stadium")], [points], null);

    Tile tile = Tile(68235, 47798, 17, 0);

    WayCropper wayCropper = WayCropper(maxDeviationPixel: 10);
    Wayholder? wayholder = wayCropper.cropWay(Wayholder.fromWay(way), tile.getBoundingBox(), 19);

    // wayCropper.steps.forEach((step) {
    //   print(step);
    // });

    datastore.addWay(way);

    var img = await (tester.runAsync(() async {
      final DisplayModel displayModel = DisplayModel();

      SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

      String content = await TestAssetBundle().loadString("rendertheme.xml");
      RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);
      Job mapGeneratorJob0 = Job(tile, false);
      JobResult jobResult1 = (await (_dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img1 = await jobResult1.picture!.convertToImage();
      return img1;
    }));

    await TestHelper.pumpWidget(tester: tester, child: RawImage(image: img), goldenfile: 'casino.png');
  });

  testWidgets("Test monaco casino east part cropping for a tile", (WidgetTester tester) async {
    _initLogging();

    MemoryDatastore datastore = MemoryDatastore();
    List<ILatLong> points = [
      const LatLong(43.727158, 7.414372),
      const LatLong(43.727378, 7.414080), // 01, clockwise outside
      const LatLong(43.727467, 7.414211),
      const LatLong(43.727551, 7.414116),
      const LatLong(43.727645, 7.414247),
      const LatLong(43.727617, 7.414285),
      const LatLong(43.727654, 7.414335),
      const LatLong(43.727808, 7.414543),
      const LatLong(43.727849, 7.414482),
      const LatLong(43.728338, 7.415164),
      const LatLong(43.728312, 7.415199),
      const LatLong(43.728402, 7.415331),
      const LatLong(43.728383, 7.415358),
      const LatLong(43.728484, 7.415494),
      const LatLong(43.728451, 7.415547),
      const LatLong(43.728573, 7.415706),
      const LatLong(43.728516, 7.415789),
      const LatLong(43.728529, 7.415986),
      const LatLong(43.728463, 7.416073),
      const LatLong(43.728510, 7.416148),
      const LatLong(43.728368, 7.416331),
      const LatLong(43.728386, 7.416364),
      const LatLong(43.728181, 7.416634),
      const LatLong(43.728164, 7.416614),
      const LatLong(43.728028, 7.416811),
      const LatLong(43.727979, 7.416734),
      const LatLong(43.727899, 7.416854),
      const LatLong(43.727873, 7.416826),
      const LatLong(43.727774, 7.416828),
      const LatLong(43.727727, 7.416877),
      const LatLong(43.727646, 7.416765),
      const LatLong(43.727618, 7.416795),
      const LatLong(43.727593, 7.416793),
      const LatLong(43.727592, 7.416751),
      const LatLong(43.727551, 7.416791),
      const LatLong(43.727457, 7.416655),
      const LatLong(43.727427, 7.416696),
      const LatLong(43.726855, 7.415893),
      const LatLong(43.726840, 7.415912), // 38, clockwise <-- too early
      const LatLong(43.726727, 7.415749),
      const LatLong(43.726760, 7.415701),
      const LatLong(43.726671, 7.415574),
      const LatLong(43.726695, 7.415537),
      const LatLong(43.726666, 7.415498),
      const LatLong(43.726627, 7.415550),
      const LatLong(43.726533, 7.415411),
      const LatLong(43.726602, 7.415321),
      const LatLong(43.726553, 7.415250),
      const LatLong(43.726632, 7.415146),
      const LatLong(43.726612, 7.415111),
      const LatLong(43.726723, 7.414970),
      const LatLong(43.726882, 7.415167),
      const LatLong(43.726934, 7.415235),
      const LatLong(43.726899, 7.415283),
      const LatLong(43.726998, 7.415418),
      const LatLong(43.726965, 7.415460),
      const LatLong(43.727643, 7.416386),
      const LatLong(43.727686, 7.416335),
      const LatLong(43.727780, 7.416469),
      const LatLong(43.727812, 7.416431),
      const LatLong(43.727868, 7.416455),
      const LatLong(43.727963, 7.416324),
      const LatLong(43.727978, 7.416346),
      const LatLong(43.728161, 7.416091),
      const LatLong(43.728147, 7.416067),
      const LatLong(43.728242, 7.415941),
      const LatLong(43.728203, 7.415887),
      const LatLong(43.728236, 7.415839),
      const LatLong(43.728143, 7.415707),
      const LatLong(43.728172, 7.415670),
      const LatLong(43.727486, 7.414718),
      const LatLong(43.727457, 7.414760),
      const LatLong(43.727362, 7.414634),
      const LatLong(43.727331, 7.414680),
      const LatLong(43.727264, 7.414591),
      const LatLong(43.727222, 7.414535),
      const LatLong(43.727250, 7.414498),
      const LatLong(43.727158, 7.414372),
    ];
    Way way = Way(0, [const Tag("building", "stadium")], [points], null);

    Tile tile = Tile(68236, 47798, 17, 0);

    WayCropper wayCropper = WayCropper(maxDeviationPixel: 10);
    Wayholder? wayholder = wayCropper.cropWay(Wayholder.fromWay(way), tile.getBoundingBox(), 19);

    // wayCropper.steps.forEach((step) {
    //   print(step);
    // });

    datastore.addWay(way);

    var img = await (tester.runAsync(() async {
      final DisplayModel displayModel = DisplayModel();

      SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

      String content = await TestAssetBundle().loadString("rendertheme.xml");
      RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);
      Job mapGeneratorJob0 = Job(tile, false);
      JobResult jobResult1 = (await (_dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img1 = await jobResult1.picture!.convertToImage();
      return img1;
    }));

    await TestHelper.pumpWidget(tester: tester, child: RawImage(image: img), goldenfile: 'casino2.png');
  });

  /// Coordinates taken from subfile_filler_test
  testWidgets("Test admin_level2 cropping for a tile", (WidgetTester tester) async {
    _initLogging();

    MemoryDatastore datastore = MemoryDatastore();
    List<ILatLong> points = [
      const LatLong(43.536831, 7.532992), // right-bottom
      const LatLong(43.516536, 7.500245), // left-bottom
      const LatLong(43.724760, 7.418523), // left-top
      const LatLong(43.729578, 7.409028),
      const LatLong(43.731106, 7.410545),
      const LatLong(43.731691, 7.412906),
      const LatLong(43.732961, 7.413078),
      const LatLong(43.733456, 7.412674),
      const LatLong(43.733965, 7.412815),
      const LatLong(43.734334, 7.412336),
      const LatLong(43.734695, 7.412701),
      const LatLong(43.739696, 7.420632),
      const LatLong(43.741414, 7.422222),
      const LatLong(43.741694, 7.422967),
      const LatLong(43.740852, 7.424507),
      const LatLong(43.741587, 7.425025),
      const LatLong(43.741433, 7.425287),
      const LatLong(43.741876, 7.425878),
      const LatLong(43.743945, 7.428058),
      const LatLong(43.746570, 7.428789),
      const LatLong(43.746862, 7.429288),
      const LatLong(43.748062, 7.429809),
      const LatLong(43.748226, 7.430439),
      const LatLong(43.749024, 7.430641),
      const LatLong(43.748867, 7.431909),
      const LatLong(43.749255, 7.432410),
      const LatLong(43.749992, 7.435978),
      const LatLong(43.751214, 7.437594),
      const LatLong(43.751605, 7.436772),
      const LatLong(43.751917, 7.436885),
      const LatLong(43.751783, 7.437780),
      const LatLong(43.751187, 7.438699),
      const LatLong(43.749383, 7.438446),
      const LatLong(43.742195, 7.452435),
      const LatLong(43.536831, 7.532992),
    ];
    Way way = Way(0, [const Tag("admin_level", "2")], [points], null);

    Tile tile = Tile(4265, 2989, 13, 0);

    WayCropper wayCropper = WayCropper(maxDeviationPixel: 10);
    Wayholder? wayholder = wayCropper.cropWay(Wayholder.fromWay(way), tile.getBoundingBox(), 19);

    // wayCropper.steps.forEach((step) {
    //   print(step);
    // });
    way.latLongs.forEach((latlongs) {
      List<String> results = [];
      String result = "";
      latlongs.forEach((latlong) {
        result += "const LatLong(${(latlong.latitude).toStringAsFixed(6)},${(latlong.longitude).toStringAsFixed(6)}),";
        if (result.length > 250) {
          results.add(result);
          result = "";
        }
      });
      if (result.isNotEmpty) results.add(result);
      results.forEach((action) {
        print("  $action");
      });
    });

    datastore.addWay(way);

    var img = await (tester.runAsync(() async {
      final DisplayModel displayModel = DisplayModel();

      SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

      String content = await TestAssetBundle().loadString("rendertheme.xml");
      RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);
      //tile = Tile(533, 373, 10, 0);
      Job mapGeneratorJob0 = Job(tile, false);
      JobResult jobResult1 = (await (_dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img1 = await jobResult1.picture!.convertToImage();
      return img1;
    }));

    await TestHelper.pumpWidget(tester: tester, child: RawImage(image: img), goldenfile: 'adminlevel.png');
  });

  /// Coordinates taken from subfile_filler_test
  testWidgets("Test admin_level2 cropping for a tile one tile above", (WidgetTester tester) async {
    _initLogging();

    MemoryDatastore datastore = MemoryDatastore();
    List<ILatLong> points = [
      const LatLong(43.536831, 7.532992), // right-bottom
      const LatLong(43.516536, 7.500245), // left-bottom
      const LatLong(43.724760, 7.418523), // left-top
      const LatLong(43.729578, 7.409028),
      const LatLong(43.731106, 7.410545),
      const LatLong(43.731691, 7.412906),
      const LatLong(43.732961, 7.413078),
      const LatLong(43.733456, 7.412674),
      const LatLong(43.733965, 7.412815),
      const LatLong(43.734334, 7.412336),
      const LatLong(43.734695, 7.412701),
      const LatLong(43.739696, 7.420632),
      const LatLong(43.741414, 7.422222),
      const LatLong(43.741694, 7.422967),
      const LatLong(43.740852, 7.424507),
      const LatLong(43.741587, 7.425025),
      const LatLong(43.741433, 7.425287),
      const LatLong(43.741876, 7.425878),
      const LatLong(43.743945, 7.428058),
      const LatLong(43.746570, 7.428789),
      const LatLong(43.746862, 7.429288),
      const LatLong(43.748062, 7.429809),
      const LatLong(43.748226, 7.430439),
      const LatLong(43.749024, 7.430641),
      const LatLong(43.748867, 7.431909),
      const LatLong(43.749255, 7.432410),
      const LatLong(43.749992, 7.435978),
      const LatLong(43.751214, 7.437594),
      const LatLong(43.751605, 7.436772),
      const LatLong(43.751917, 7.436885),
      const LatLong(43.751783, 7.437780),
      const LatLong(43.751187, 7.438699),
      const LatLong(43.749383, 7.438446),
      const LatLong(43.742195, 7.452435),
      const LatLong(43.536831, 7.532992),
    ];
    Way way = Way(0, [const Tag("admin_level", "2")], [points], null);

    Tile tile = Tile(4265, 2988, 13, 0);

    WayCropper wayCropper = WayCropper(maxDeviationPixel: 10);
    Wayholder? wayholder = wayCropper.cropWay(Wayholder.fromWay(way), tile.getBoundingBox(), 19);

    datastore.addWay(way);

    var img = await (tester.runAsync(() async {
      final DisplayModel displayModel = DisplayModel();

      SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

      String content = await TestAssetBundle().loadString("rendertheme.xml");
      RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);
      //tile = Tile(533, 373, 10, 0);
      Job mapGeneratorJob0 = Job(tile, false);
      JobResult jobResult1 = (await (_dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img1 = await jobResult1.picture!.convertToImage();
      return img1;
    }));

    await TestHelper.pumpWidget(tester: tester, child: RawImage(image: img), goldenfile: 'adminlevel2.png');
  });
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
