import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'constants.dart';
import 'filehelper.dart';

class MapModelHelper {
  static Future<MapModel> prepareMapModel() async {
    String _localPath = await FileHelper.findLocalPath();

    File file = File(_localPath + "/" + Constants.mapfile);
    print("opening mapfile");
    RandomAccessFile raf = await file.open();
    MapFile mapFile = MapFile(raf, null, null);
    await mapFile.init();
    //await mapFile.debug();

    final DisplayModel displayModel = DisplayModel();
    GraphicFactory graphicFactory = FlutterGraphicFactory();

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    print("Rendering instructions has ${content.length} bytes");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    TileBasedLabelStore labelStore = TileBasedLabelStore(100);
    MapDataStoreRenderer dataStoreRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true, labelStore);
    TileCache tileCache = MemoryTileCache(50);
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: dataStoreRenderer,
      tileCache: tileCache,
    );
    return mapModel;
  }
}
