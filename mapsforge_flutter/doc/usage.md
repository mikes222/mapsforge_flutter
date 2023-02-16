## Renderer

todo

## Marker

If you want your own marker datastore add one or more of the following to the MapModel:

    MarkerDataStore markerDataStore = MarkerDataStore();
    markerDataStore.addMarker(PoiMarker(src: "jar:symbols/windsock.svg",
      latLong: const LatLong(48.089355, 16.311509),
      ));

and include the new datastore in the mapModel.

    mapModel.markerDataStores.add(markerDataStore);

You can add many markers to a datastore and you can
add many datastores to the model.

Note: We provide also datastores for single markers as well as ClusterDatastores for many marker which
should be clustered when zooming out

Note: We provide a bunch of different markers. Markers with images like PoiMarkers, PathMarkers, RectMarkers, CircleMarkers and more

## ContextMenu

ContextMenus are created with the contextMenuBuilder. Add one to the viewModel:

    ViewModel viewModel = ViewModel(
          displayModel: displayModel,
          contextMenuBuilder: const DefaultContextMenuBuilder(),
        );

## Overlays

Overlays are drawn on top of the map and refresh of the overlay is triggered whenever the position or zoom
changes. Overlays are simple Widgets. Add them to the viewModel:

    viewModel.addOverlay(DistanceOverlay(viewModel));

## Input gestures

The default GestureDetector can deal with the following gestures:

Double click: Default behavior: zoom in at the coordinates of the click
Short click: Default behavior: show context menu
Long click: Default behavior: none
Pinch-to-zoom: Default behavior: zoom in/out at the specified focus point
Click-hold, then move: Default behavior: none

In order to receive the gestures and implement your own code check the appropriate observe* methods in ViewModel


## Tipps

### Use isolates
Flutter itself does not support Threads. Instead everything is performed in the main thread - also ui functionality. It may happen that the system blocks the ui if many cpu-intensive calculations are done. Calculating tiles is definitely cpu-intensive. Although we have done a lot to mitigate this sometimes it is not enough.

Isolates are flutter's way to support threads. An isolate is just another runtime which is totally independent to the ui runtime. Communication between isolates are done by serializing data and deserializing the at the other isolate. Therefore we have an overhead by transferring data between the isolates. In the current versions of this libary the work which can be done in an isolate normally justifies this overhead so feel free to check it out. When instantiating the ``MapDataStoreRenderer`` just set the ``useIsolate`` property to ``true``

### Pixels vs. Screen pixels

The data in the mapfile are stored in Latitude/Longitude coordinates. We use the ``PixelProjection`` class to convert from Latitude/Longitude to Pixel and vice versa. Please note that Flutter uses a resolution-independent algorithm for pixels. 800px in Flutter is more or less the same visual size on all Flutter devices. However the device itself is often capable of displaying a much greater resolution. So whereas the Pixelsize of Flutter reports a resolution of for example 800*600 pixels the device itself can display for example 2560x1440 pixels. That is why the map sometimes looks unsharp.

In order to mitigate this set the ``deviceScaleFactor`` in ``DisplayModel`` to a value larger than one. This way the tiles will be created with a larger resolution and displayed accordingly in the widget. 