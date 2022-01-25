# mapsforge_flutter


Pure offline maps for flutter. This is a port of mapsforge for java/android [https://github.com/mapsforge/mapsforge]

> If your users are online while viewing the maps do not use that library. While it is possible to show online-maps there
are much simpler libs available out there to perform this task. 

The main feature of this library is to read *mapfiles* stored locally at the user's device and render the
mapfiles directly on the user's device without internet connection. 

## Screenshots

![Austria offline](doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

## Examples

Please find an example APP in the subdirectory [../example/README.md](../example/README.md)

## Limitations

Everything is called in the same thread, isolates are flutter's way of threads but calling native functions is currently not possible in isolates.
All graphical functions are native functions. 
 - So currently the whole rendering is done in the ui thread which leads to blocked ui while rendering (only a couple of milliseconds) 
 See https://github.com/flutter/flutter/issues/13937

Reading from MapFiles are now done in isolates so at least a portion of the rendering process does not block the UI anymore

## Credits

First and foremost to the author of mapsforge. He has done an outstanding job!

Also to the university of chemnitz which implements indoor map support

## TODO

Speed:
 - support for more than one concurrent job in the jobqueue

Others:
 - Testing for IOS

## Getting Started

### Prerequisites

include the library in your pubspec.yaml:

```yaml
  mapsforge_flutter: ^2.0.1
    # path: ../mapsforge_flutter
    # git:
    #  url: https://github.com/mikes222/mapsforge_flutter
```

include a list of all used assets in your pubspec.yaml (see  pubspec file from example project)

```yaml
    flutter:
    
      assets:
       - packages/mapsforge_flutter/assets/patterns/coniferous.svg
       - packages/mapsforge_flutter/assets/patterns/coniferous_and_deciduous.svg
       - packages/mapsforge_flutter/assets/patterns/deciduous.svg
    ...
```

### Initializing mapsforge

Load the mapfile which holds the openstreetmap &reg; data

> Mapfiles are files specifically designed for mobile use and provide the
information about an area in condensed form. Please visit the original project for more information about how to download/generate them. 


```dart
MapFile mapFile = MapFile(_localPath + "/" + mapfile, null, null);
await mapFile.init();
```

Create the cache for assets 

> assets are mostly small images to display in the map, for example parking signs, bus stop signs and so on


```dart
SymbolCache symbolCache = SymbolCache(rootBundle);
```

Create the graphicFactory wich implements the drawing capabilities for flutter. The original implementation have different graphicFactories for android as well for java AWT. This project does have just one (for now) but we want to keep the structure of the original implementation. 


```dart
GraphicFactory graphicFactory = FlutterGraphicFactory();
```

Create the displayModel which defines and holds the view/display settings like maximum zoomLevel.


```dart
DisplayModel displayModel = DisplayModel();
```

Create the render theme which specifies how to render the informations from the mapfile. 

> You can think of it like a css-file for mapsforge


```dart
RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
String content = await rootBundle.loadString("assets/defaultrender.xml");
await renderThemeBuilder.parseXml(content);
RenderTheme renderTheme = renderThemeBuilder.build();
```

Create the Renderer.

> The renderer is the rendering engine for the mapfiles. This code does the main work to render the contents of a
mapfile together with the design guides from the rendertheme into bitmap tiles. bitmap tiles are png files with a fixed width/height.


```dart
MapDataStoreRenderer jobRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true);
```

Alternatively use the onlineRenderer instead to provide the tiles from openstreetmap &reg;

> By using the online-renderer you will not need the rendertheme nor the mapfiles. 


```dart
jobRenderer = MapOnlineRenderer();
```

Optionally you can create a cache for the bitmap tiles. The tiles will survive a restart but may fill the disk space.


```dart
FileTileBitmapCache bitmapCache = FileTileBitmapCache(jobRenderer.getRenderKey());
```

Glue everything together into two models. 

> The mapModel holds all map-relevant informations whereas the viewModel holds all 
informations related to how to display the map for the current widget


```dart
MapModel mapModel = MapModel(
  displayModel: displayModel,
  graphicsFactory: graphicFactory,
  renderer: jobRenderer,
  symbolCache: symbolCache,
  tileBitmapCache: bitmapCache,  
);

ViewModel viewModel = ViewModel(displayModel: displayModel);
```

In your ``build()`` method of the widget include the mapView:


```dart
FlutterMapView( mapModel: mapModel, viewModel: viewModel, ),
```

In order to change the position in the map programmatically call the viewModel with the new position


```dart
viewModel.setMapViewPosition(48.0901926, 16.308939);
```

Similar methods exists for zooming. 

### Marker

If you want your own marker datastore add one or more of the following to the MapModel:


```dart
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
```

and include the new datastore in the mapModel. You can add many markers to a datastore and you can add many datastores to the model. 

### ContextMenu

todo

----

For more information and documentation check [doc/mapdatastore.md](doc/mapdatastore.md)

----

## License

Same license as the original mapsforge project. LPGL-v3

## Contribution

Help is appreciated...

- support map rotating (do not rotate the text and icons then)
- some flaws with text spawning multiple tiles
- Unit tests!
