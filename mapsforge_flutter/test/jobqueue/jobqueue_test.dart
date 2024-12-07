import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/model/tile_dimension.dart';

import '../testassetbundle.dart';

void main() {
  testWidgets("Test JobQueue", (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(deviceScaleFactor: 2);
    MapFile datastore = await MapFile.from(
        TestAssetBundle().correctFilename("monaco.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    JobSet? jobSet = await tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");

      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();
      SymbolCache symbolCache = FileSymbolCache(
          imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);
      TileBitmapCache tileBitmapCache1stLevel = MemoryTileBitmapCache.create();

      JobQueue jobQueue =
          JobQueue(_dataStoreRenderer, null, tileBitmapCache1stLevel);

      ViewModel viewModel = ViewModel(displayModel: displayModel);
      viewModel.setMapViewPosition(50.841125, 12.927887);
      viewModel.setZoomLevel(16);

      print(
          "${viewModel.mapViewPosition!.projection.latLonToPixel(LatLong(viewModel.mapViewPosition!.latitude!, viewModel.mapViewPosition!.longitude!))}");
      print(
          "${viewModel.mapViewPosition!.projection.longitudeToTileX(viewModel.mapViewPosition!.longitude!)} - ${viewModel.mapViewPosition!.projection.latitudeToTileY(viewModel.mapViewPosition!.latitude!)}");

      JobSet? jobSet = jobQueue.createJobSet(
          viewModel,
          viewModel.mapViewPosition!,
          MapSize(
              width: 778 * viewModel.viewScaleFactor,
              height: 1146 * viewModel.viewScaleFactor));
      assert(jobSet != null);
      return jobSet!;
    });
    expect(jobSet!.zoomLevel, equals(16));
    expect(jobSet.getCenter(),
        equals(const Mappoint(17982182.403458845, 11256759.797551334)));
    expect(
        jobSet.tileDimension,
        const TileDimension(
            left: 35119, right: 35122, top: 21983, bottom: 21988));
    expect(
        jobSet.boundingBox,
        BoundingBox(50.83022820561744, 12.9144287109375, 50.851041129659485,
            12.9364013671875));
  });
}
