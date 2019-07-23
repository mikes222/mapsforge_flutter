import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'constants.dart';
import 'customnopositionview.dart';
import 'filehelper.dart';

class MapModelHelper {
  static Future<MapModel> prepareMapModel() async {
    String _localPath = await FileHelper.findLocalPath();

    MultiMapDataStore multiMapDataStore = MultiMapDataStore(DataPolicy.DEDUPLICATE);

    {
      print("opening mapfile");
      ReadBuffer readBuffer = ReadBuffer(_localPath + "/" + Constants.worldmap);
      MapFile mapFile = MapFile(readBuffer, null, null);
      await mapFile.init();
      //await mapFile.debug();
      multiMapDataStore.addMapDataStore(mapFile, true, true);
    }
    {
      print("opening mapfile");
      ReadBuffer readBuffer = ReadBuffer(_localPath + "/" + Constants.mapfile);
      MapFile mapFile = MapFile(readBuffer, null, null);
      await mapFile.init();
      //await mapFile.debug();
      multiMapDataStore.addMapDataStore(mapFile, false, false);
    }

    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    JobRenderer jobRenderer = MapDataStoreRenderer(multiMapDataStore, renderTheme, graphicFactory, true);
    //JobRenderer jobRenderer = MapOnlineRenderer();
    //JobRenderer jobRenderer = DummyRenderer();

    FileBitmapCache bitmapCache = FileBitmapCache(jobRenderer.getRenderKey());
    Timer(Duration(milliseconds: 1000), () {
      // init of cache is async, so wait until init is finished an then purge the cache.
      //bitmapCache.purge();
    });

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      bitmapCache: bitmapCache,
      noPositionView: CustomNoPositionView(),
    );

    MarkerDataStore markerDataStore = MarkerDataStore();
    markerDataStore.markers.add(PoiMarker(
      src: "jar:symbols/windsock.svg",
      symbolCache: symbolCache,
      width: 40,
      height: 40,
      caption: "TestMarker",
      latLong: LatLong(48.089355, 16.311509),
    ));
    markerDataStore.markers.add(PathMarker(strokeWidth: 15.0, strokeColor: 0x80ff6000)
      ..addLatLong(LatLong(48.093160, 16.314303))
      ..addLatLong(LatLong(48.087026, 16.313660))
      ..addLatLong(LatLong(48.086883, 16.301536))
      ..addLatLong(LatLong(48.089935, 16.301729))
      ..addLatLong(LatLong(48.090236, 16.295893)));
    markerDataStore.markers.add(PolygonMarker()
      ..addLatLong(LatLong(48.103420, 16.307523))
      ..addLatLong(LatLong(48.097876, 16.300013))
      ..addLatLong(LatLong(48.105885, 16.302523)));
    mapModel.markerDataStores.add(markerDataStore);

    return mapModel;
  }

  static Future<MapModel> prepareOnlineMapModel() async {
    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

    //JobRenderer jobRenderer = MapDataStoreRenderer(multiMapDataStore, renderTheme, graphicFactory, true);
    JobRenderer jobRenderer = MapOnlineRenderer();
    //JobRenderer jobRenderer = DummyRenderer();

    FileBitmapCache bitmapCache = FileBitmapCache(jobRenderer.getRenderKey());
//    bitmapCache.purge();

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      bitmapCache: bitmapCache,
      noPositionView: CustomNoPositionView(),
    );

    MarkerDataStore markerDataStore = MarkerDataStore();
    markerDataStore.markers.add(PoiMarker(
      src: "jar:symbols/windsock.svg",
      symbolCache: symbolCache,
      width: 40,
      height: 40,
      caption: "TestMarker",
      latLong: LatLong(48.089355, 16.311509),
    ));
    mapModel.markerDataStores.add(markerDataStore);

    return mapModel;
  }
}
