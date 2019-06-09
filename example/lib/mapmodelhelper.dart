import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
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

    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    print("Rendering instructions has ${content.length} bytes");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    TileBasedLabelStore labelStore = TileBasedLabelStore(100);
    MapDataStoreRenderer dataStoreRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true, labelStore);

    DummyRenderer dummyRenderer = DummyRenderer();

    MarkerDataStore markerDataStore = MarkerDataStore();
    markerDataStore.markers.add(BasicMarker(
      src: "jar:symbols/windsock.svg",
      symbolCache: symbolCache,
      width: 20,
      height: 20,
      graphicFactory: graphicFactory,
      caption: "TestMarker",
      latitude: 48.089355,
      longitude: 16.311509,
    )..init());

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: dataStoreRenderer,
      symbolCache: symbolCache,
      markerDataStore: markerDataStore,
    );
    return mapModel;
  }
}
