# mapsforge_flutter

Pure offline maps for flutter. This is a port of mapsforge for java/android. 

Please take a look at the original library for android and java:

[https://github.com/mapsforge/mapsforge]()

If your users are online while showing the maps do not use that library. While it is possible to show online-maps from openstreetmap there
are much simpler libs available out there to perform this job. 

The main feature of this library is to read mapfiles locally stored at the user's device and render the
map directly on the user's device. The user does not need to have an internet connection once the mapfiles are stored locally.

## Limitations

Everything is called in the same thread, isolates are flutter's way of threads but calling native functions is currently not possible in isolates.
All graphical functions are native functions. 
 - So currently the whole rendering is done in the ui thread which leads to blocked ui while rendering. 
 See https://github.com/flutter/flutter/issues/13937

*Update:* The reading from MapFiles are now done in isolates so at least a portion of the rendering process does not block the UI anymore

## Credits

First and foremost to the author of mapsforge. He has done an outstanding job!

Also to the university of chemnitz which implements indoor map support

## TODO

graphics:
 - animate movement
 - fling

Speed:
 - support for more than one concurrent job in the jobqueue (rudimentary implemented already)

Others:
 - Testing for IOS
 - tile size others than 256 pixels may break the code

## Getting Started

### Prerequisites

include the library in your pubspec.yaml:

      mapsforge_flutter: ^1.1.0
        # path: ../mapsforge_flutter

include a list of all used assets in your pubspec.yaml (see  pubspec file from example project)

    flutter:
    
      assets:
       - packages/mapsforge_flutter/assets/patterns/coniferous.svg
       - packages/mapsforge_flutter/assets/patterns/coniferous_and_deciduous.svg
       - packages/mapsforge_flutter/assets/patterns/deciduous.svg
    ...

### Initializing mapsforge

Load the mapfile which holds the openstreetmap &reg; data: Mapfiles are files specifically designed for mobile use and provide the
information about an area in condensed form. Please visit the original project for more information about how to download/generate them. 

    MapFile mapFile = MapFile(_localPath + "/" + mapfile, null, null);
    await mapFile.init();

Create the cache for assets (small images to display at the map)

    SymbolCache symbolCache = SymbolCache(rootBundle);

Create the graphicFactory wich implements the drawing capabilities for flutter. The original implementation have different graphicFactories for
android as well for java AWT. This project does have just one (for now) but we want to keep the structure of the original implementation. 

    GraphicFactory graphicFactory = FlutterGraphicFactory(symbolCache);

Create the displayModel which defines the view/display settings like maximum zoomLevel.

    final DisplayModel displayModel = DisplayModel();

Create the render theme which specifies how to render the informations from the mapfile. (You can think of it like a css-file)

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

Create the Renderer which is the rendering engine for the mapfiles. This code does the main work to render the contents of a
mapfile together with the design guides from the rendertheme into bitmap tiles. bitmap tiles are png files with a fixed width/height.

    MapDataStoreRenderer jobRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true);

Alternatively use the onlineRenderer instead to provide the tiles from openstreetmap &reg; (you will not need the rendertheme nor the mapfiles then)

    jobRenderer = MapOnlineRenderer();

Optionally you can create a cache for the bitmap tiles. The tiles will survive a restart but may fill the disk space.

    FileTileBitmapCache bitmapCache = FileTileBitmapCache(jobRenderer.getRenderKey());

Glue everything together

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      tileBitmapCache: bitmapCache,  
    );

Create a viewModel which holds all the information how to view/display the map

    ViewModel viewModel = ViewModel(displayModel: displayModel);

In your ``build()`` method include the mapView:

    FlutterMapView( mapModel: mapModel, viewModel: viewModel, ),

In order to change the position in the map call the viewModel with the new position

    viewModel.setMapViewPosition(48.0901926, 16.308939);

similar for zooming.

### Marker

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

### ContextMenu

todo

----

For more information and documentation check [resources/docu/mapdatastore.md](resources/docu/mapdatastore.md)

----

## License

Same license as the original mapsforge project. LPGL-v3

## Contribution

Help is appreciated...

- support map rotating (do not rotate the text and icons then)
- some flaws with text spawning multiple tiles
- Unit tests!
- Hillshading
