# mapsforge_flutter

A port of mapsforge for pure flutter. The library is in an early stage. 

Please take a look at the original library for android and java:

https://github.com/mapsforge/mapsforge

Same license as the original mapsforge project. LPGL-v3

## Limitations

Currently flutter has no support for dashed lines

doubleTap() does not provide a location. See https://github.com/flutter/flutter/issues/20000 But there is a workaround which I have already implemented. 

Everything is called in the same thread, isolates are flutter's way of threads but calling native functions is currently not possible in isolates. 
All graphical functions are native functions. 
 - So currently the whole rendering is done in the ui thread which leads to blocked ui while rendering. 
 See https://github.com/flutter/flutter/issues/13937

Update: The reading from MapFiles are now done in isolates so at least a portion of the rendering process does not block the UI anymore

## Credits

First and foremost to the author of mapsforge. He has done an outstanding job!

## TODO

graphics:
 - animate movement
 - animate zoom (currently no visual feedback while pinch&zooming)
 - fling
 
Speed:
 - support for more than one concurrent job in the jobqueue (rudimentary implemented already)

Others:
 - Testing for IOS
 - tile size others than 256 pixels may break the code

## Getting Started

### Prerequisites

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

### Loading an offline map

Load the mapfile which holds the openstreetmap (r) data: Mapfiles are files specifically designed for mobile use and provide the
information about an area in condensed form. Please visit the original project for more information about how to download/generate them. 

    String _localPath = await FileHelper.findLocalPath();

    MapFile mapFile = MapFile(_localPath + "/" + mapfile, null, null);
    await mapFile.init();
    //await mapFile.debug();

Create the graphicFactory wich implements the drawing algorithms for flutter. The original implementation have different graphicFactories for 
android as well for java AWT. This project does have just one (for now) but we want to keep the structure of the original implementation. 

    GraphicFactory graphicFactory = FlutterGraphicFactory();

Create the displayModel which defines the most important settings for mapsforge. 

    final DisplayModel displayModel = DisplayModel();

Create the cache for assets.

    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

Create the render theme which specifies how to render the informations from the mapfile. (You can think of it like a css-file for html) 

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

Create the MapDataStoreRenderer which is the rendering engine for the mapfiles. This code does the main work to render the contents of a 
mapfile together with the design guides from the render theme into map tiles. Map tiles are png files with a fixed with/height. 

    MapDataStoreRenderer dataStoreRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true);

Glue everything together

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: dataStoreRenderer,
      symbolCache: symbolCache,
    );

In your view's build() function include the mapsview:

    FlutterMapView( mapModel: mapModel,  ),

In order to change the position in the map call the mapModel with the new position

    mapModel.setMapViewPosition(48.0901926, 16.308939);
    
If you want your own marker datastore add one or more of the following to the MapModel:

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

and include the new datastore in the mapModel. You can add many markers to a datastore and you can add many datastores to the model. 

### Loading an online map

Instantiate a graphicFactory (same as in previous chapter)

    GraphicFactory graphicFactory = FlutterGraphicFactory();

Instantiate the displayModel

    final DisplayModel displayModel = DisplayModel();

Instantiate a symbolCache

    SymbolCache symbolCache = SymbolCache(graphicFactory, displayModel);

Instantiate the online renderer which does the main job. It downloads requested tiles (png-files) from openstreetmap. See their license!

    //JobRenderer jobRenderer = MapDataStoreRenderer(multiMapDataStore, renderTheme, graphicFactory, true);
    JobRenderer jobRenderer = MapOnlineRenderer();
    //JobRenderer jobRenderer = DummyRenderer();

Start the bitmap cache

    FileBitmapCache bitmapCache = FileBitmapCache(jobRenderer.getRenderKey());

Glue everything together

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      bitmapCache: bitmapCache,
      noPositionView: CustomNoPositionView(),
    );

Follow the steps above to implement the new map into your widget

-----------------

For more information and documentation check mapsforge_flutter/resources/docu/mapdatastore.md

-----------------

Help is appreciated...

- Solving speed issues
- support map rotating (do not rotate the text and icons then)
- some flaws with text spawning multiple tiles
- bring the project to https://pub.dev/packages
- Unit tests!

