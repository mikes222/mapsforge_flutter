import 'dart:async';

import 'package:example/constants.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'filehelper.dart';

class MapModelHelper {
  static final _log = new Logger('MapModelHelper');

  static Future<MapModel> prepareMapModel() async {
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
      _log.info("opening mapfile ${_localPath + "/" + Constants.MAPFILE_NAME}");
      MapFile mapFile = MapFile(_localPath + "/" + Constants.MAPFILE_NAME, null, null);
      await mapFile.init();
      //await mapFile.debug();
      //mapDataStore.addMapDataStore(mapFile, false, false);
      mapDataStore = mapFile;
    }

    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    SymbolCache symbolCache = SymbolCache();

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    JobRenderer jobRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, true);

    FileTileBitmapCache bitmapCache = FileTileBitmapCache(jobRenderer.getRenderKey());

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      tileBitmapCache: bitmapCache,
    );

    // set default position
    mapModel.setMapViewPosition(Constants.MAP_POSITION_LAT, Constants.MAP_POSITION_LON);

    mapModel.setZoomLevel(Constants.MAP_ZOOM_LEVEL);

    return mapModel;
  }
}
