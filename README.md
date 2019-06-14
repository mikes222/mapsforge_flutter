# mapsforge_flutter

A port of mapsforge for pure flutter. The library is in an early stage. 

Please take a look at the original library for android and java:

https://github.com/mapsforge/mapsforge

Same license as the original mapsforge project. LPGL-v3

## Limitations

Currently flutter has no support for dashed lines

doubleTap() does not provide a location. See https://github.com/flutter/flutter/issues/20000 But there is a workaround which I have already implemented. 

Everything is called in the same thread, isolates are flutter's way of threads but calling native functions is currently not possible in isolates. All graphical functions are native functions. 
So currently the whole rendering is done in the ui thread which leads to blocked ui while rendering. See https://github.com/flutter/flutter/issues/13937

## Credits

First and foremost to the author of mapsforge. He has done an outstanding job!

## TODO

A lot of things. 

graphics:
 - rotate path text
 - animate movement
 - animate zoom
 
User Input:
 - zoom in/out (already implemented but without visual feedback while zooming)
  
Speed:
 - support for more than one concurrent job in the jobqueue (rudimentary implemented already)

Others:
 - Online Tiles
 - Way Database
 - Testing for ios
  

## Getting Started

include the library in your pubspec.yaml:

      mapsforge_flutter:
        path: ../mapsforge_flutter

include a list of all used assets in your pubspec.yaml (see  pubspec file from example project)

    flutter:
    
      assets:
       - packages/mapsforge_flutter/assets/patterns/coniferous.svg
       - packages/mapsforge_flutter/assets/patterns/coniferous_and_deciduous.svg
       - packages/mapsforge_flutter/assets/patterns/deciduous.svg
    ...

Load the mapfile which holds the openstreetmap (r) data:

    String _localPath = await FileHelper.findLocalPath();

    File file = File(_localPath + "/" + Constants.mapfile);
    RandomAccessFile raf = await file.open();
    MapFile mapFile = MapFile(raf, null, null);
    await mapFile.init();
    //await mapFile.debug();

Create the graphicFactory wich implements the drawing algorithms for flutter

    GraphicFactory graphicFactory = FlutterGraphicFactory();

Create the displayModel which defines the most important settings for mapsforge

    final DisplayModel displayModel = DisplayModel();

Create the cache for assets

    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

Create the render theme which specifies how to render the informations from the mapfile

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

Create the MapDataStoreRenderer which is the rendering engine for the mapfiles

    MapDataStoreRenderer dataStoreRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true);

Glue everything together

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: dataStoreRenderer,
      symbolCache: symbolCache,
    );

In your build function include the mapsview:

    FlutterMapView( mapModel: mapModel,  ),

In order to change the position in the map call the mapModel with the new position

    mapModel.setMapViewPosition(48.0901926, 16.308939);
    
If you want your own marker datastore add the following to the MapModel:

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

and include the new datastore in the mapModel.

-----------------

Help is appreciated...
