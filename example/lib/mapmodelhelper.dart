import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'constants.dart';
import 'customnopositionview.dart';
import 'filehelper.dart';

class MapModelHelper {
  static final _log = new Logger('MapModelHelper');

  static Future<MapModel> prepareOfflineMapModel() async {
    String _localPath = await FileHelper.findLocalPath();

    MapDataStore mapDataStore; //= MultiMapDataStore(DataPolicy.DEDUPLICATE);
//    {
//      print("opening mapfile");
//      ReadBuffer readBuffer = ReadBuffer(_localPath + "/" + Constants.worldmap);
//      MapFile mapFile = MapFile(readBuffer, null, null);
//      await mapFile.init();
//      //await mapFile.debug();
//      multiMapDataStore.addMapDataStore(mapFile, true, true);
//    }
    {
      _log.info("opening mapfile ${Constants.mapfile}");
      MapFile mapFile = MapFile(_localPath + "/" + Constants.mapfile, null, null);
      await mapFile.init();
      //await mapFile.debug();
      //mapDataStore.addMapDataStore(mapFile, false, false);
      mapDataStore = mapFile;
    }

    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    JobRenderer jobRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, true);
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
      markerCaption: MarkerCaption(text: "TestMarker"),
      latLong: LatLong(48.089355, 16.311509),
    ));
    markerDataStore.markers.add(PathMarker(strokeWidth: 15.0, strokeColor: 0x80ff6000)
      ..addLatLong(LatLong(48.093160, 16.314303))
      ..addLatLong(LatLong(48.087026, 16.313660))
      ..addLatLong(LatLong(48.086883, 16.301536))
      ..addLatLong(LatLong(48.089935, 16.301729))
      ..addLatLong(LatLong(48.090236, 16.295893)));
    markerDataStore.markers.add(PolygonMarker(markerCaption: MarkerCaption(text: "ExamplePolygon"))
      ..addLatLong(LatLong(48.103420, 16.307523))
      ..addLatLong(LatLong(48.097876, 16.300013))
      ..addLatLong(LatLong(48.105885, 16.302523)));
    markerDataStore.markers.add(
        PolygonMarker(src: "jar:symbols/volcano.svg", symbolCache: symbolCache, markerCaption: MarkerCaption(text: "Polygon with volcanos"))
          ..addLatLong(LatLong(48.095153, 16.334903))
          ..addLatLong(LatLong(48.086409, 16.344301))
          ..addLatLong(LatLong(48.097446, 16.325161)));
    markerDataStore.markers
        .add(RectMarker(minLatLon: LatLong(48.1, 16.3), maxLatLon: LatLong(48.12, 16.32), fillColor: 0x30ff6000, strokeColor: 0x800060ff));
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
      markerCaption: MarkerCaption(text: "TestMarker"),
      latLong: LatLong(48.089355, 16.311509),
    ));
    mapModel.markerDataStores.add(markerDataStore);

    return mapModel;
  }
}
