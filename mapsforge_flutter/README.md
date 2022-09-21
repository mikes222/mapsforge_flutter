# mapsforge_flutter

Pure offline maps for flutter. This is a port of mapsforge for
java/android [https://github.com/mapsforge/mapsforge]

The main feature of this library is to read *mapfiles* stored locally at the user's device and
render the mapfiles directly on the user's device without internet connection.

> If your users are online while viewing the maps do not use that library. 
> While it is possible to show online-maps there are much simpler libs available out there to perform this task.

## Screenshots

![Austria offline](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

## Examples

Please find an example APP in the subdirectory [../example/README.md](../example/README.md)

## Limitations

In Flutter everything is called in the same thread, isolates are flutter's way of threads but calling ui
functions is currently not possible in secondary isolates. All graphical methods which are used to 
cretae the tiles are ui functions.

- So currently the whole rendering is done in the ui thread which leads to blocked ui while
  rendering (only a couple of milliseconds)
  See https://github.com/flutter/flutter/issues/13937
  See https://github.com/flutter/flutter/issues/10647

Markers are currently not scaled while pinch'n'zoom

## Credits

First and foremost to the author of mapsforge. He has done an outstanding job!

Also to the university of chemnitz which implements indoor map support

## TODO

Speed:

- support for more than one concurrent job in the jobqueue
- check why the IndexCache is read 512 times with only 13 entries containing

Others:

- support rotating map (do not rotate the text and icons)
- crisper view (take the physical resolution of screens into account)
- some flaws with text spawning multiple tiles
- Unit tests

## Getting Started

### Prerequisites

include the library in your pubspec.yaml:

```yaml
  mapsforge_flutter: ^2.0.2
    # path: ../mapsforge_flutter
    # git:
  #  url: https://github.com/mikes222/mapsforge_flutter
```

include a list of all used assets in your ``pubspec.yaml`` (see pubspec file from example project)

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

> Mapfiles are files specifically designed for mobile use and provide the information about an area in condensed form. Please visit the original project for more information about how to download/generate them.

    MapFile mapFile = await MapFile.from(filename, null, null);```

or

    MapFile mapFile = await MapFile.using(content, null, null);

Note: Destroy the mapfile by calling ``dispose()`` if not needed anymore

Create the cache for assets

> assets are mostly small images to display in the map, for example parking signs, bus stop signs and so on

    SymbolCache symbolCache = FileSymbolCache();

Create the displayModel which defines and holds the view/display settings like maximum zoomLevel.

    DisplayModel displayModel = DisplayModel();

Create the render theme which specifies how to render the informations from the mapfile.

> You can think of it like a css-file for mapsforge

    RenderTheme renderTheme = await
    RenderThemeBuilder.create(displayModel, "assets/render_themes/defaultrender.xml");

Create the Renderer.

> The renderer is the rendering engine for the mapfiles. This code does the main work to render the contents of a mapfile together with the design guides from the rendertheme into bitmap tiles. bitmap tiles are png files with a fixed width/height. Multiple tiles together form the mapview.

    JobRenderer jobRenderer = MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

Alternatively use the onlineRenderer instead to provide the tiles from openstreetmap &reg;

> By using the online-renderer you will not need the rendertheme nor the mapfiles.

    JobRenderer jobRenderer = MapOnlineRenderer();

Optionally you can create a cache for the bitmap tiles. The tiles will survive a restart but may
fill the disk space.

    TileBitmapCache bitmapCache = await FileTileBitmapCache.create(jobRenderer.getRenderKey());

Glue everything together into two models.

> The mapModel holds all map-relevant informations whereas the viewModel holds all informations related to how to display the map for the current widget

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      tileBitmapCache: bitmapCache,
    );
    
    ViewModel viewModel = ViewModel(displayModel: displayModel);

Include the mapView in the ``build()`` method of your APP:

    FlutterMapView(mapModel: mapModel, viewModel: viewModel );

Voilà you are done. 

---

In order to change the position in the map programmatically call the viewModel with the new position

    viewModel.setMapViewPosition(48.0901926 , 16.308939);

Similar methods exists for zooming.

### Marker

If you want your own marker datastore add one or more of the following to the MapModel:

    MarkerDataStore markerDataStore = MarkerDataStore();
    markerDataStore.addMarker(PoiMarker(src: "jar:symbols/windsock.svg",
      latLong: const LatLong(48.089355, 16.311509),
      ));

and include the new datastore in the mapModel. 

    mapModel.markerDataStores.add(markerDataStore);

You can add many markers to a datastore and you can
add many datastores to the model.

### ContextMenu

ContextMenus are created with the contextMenuBuilder. Add one to the viewModel:

    ViewModel viewModel = ViewModel(
          displayModel: displayModel,
          contextMenuBuilder: const DefaultContextMenuBuilder(),
        );

### Overlays

Overlays are drawn on top of the map and refresh of the overlay is triggered whenever the position or zoom
changes. Overlays are simple Widgets. Add them to the viewModel:

    viewModel.addOverlay(DistanceOverlay(viewModel));

----

For more information and documentation check [doc/mapdatastore.md](doc/mapdatastore.md)

----

### Input gestures

The default GestureDetector can deal with the following gestures:

Double click: Default behavior: zoom in at the coordinates of the click
Short click: Default behavior: show context menu
Long click: Default behavior: none
Pinch-to-zoom: Default behavior: zoom in/out at the specified focus point
Click-hold, then move: Default behavior: none

In order to receive the gestures and implement your own code check the appropriate observe* methods in ViewModel

## License

Same license as the original mapsforge project. LPGL-v3

## Contribution

Help is appreciated...

If you find some bug or make enhancements feel free to contribute via PullRequests. 
Also feel free to create bug reports in github.