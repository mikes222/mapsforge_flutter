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
      bitmapCache.purge();
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
    markerDataStore.markers.add(BasicMarker(
      src: "jar:symbols/windsock.svg",
      symbolCache: symbolCache,
      width: 40,
      height: 40,
      caption: "TestMarker",
      latitude: 48.089355,
      longitude: 16.311509,
    ));
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
    markerDataStore.markers.add(BasicMarker(
      src: "jar:symbols/windsock.svg",
      symbolCache: symbolCache,
      width: 40,
      height: 40,
      caption: "TestMarker",
      latitude: 48.089355,
      longitude: 16.311509,
    ));
    mapModel.markerDataStores.add(markerDataStore);

    return mapModel;
  }
}
