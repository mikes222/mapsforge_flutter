import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_example/mapfileanalyze/mapheaderpage.dart';
import 'package:mapsforge_example/markerdemo-contextmenubuilder.dart';
import 'package:mapsforge_example/markerdemo-datastore.dart';
import 'package:mapsforge_example/rotation-slider-overlay.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/overlay.dart';

import 'debug/debug-contextmenubuilder.dart';
import 'debug/debug-datastore.dart';
import 'map-file-data.dart';

/// The [StatefulWidget] displaying the interactive map page. This is a demo
/// implementation for using mapsforge's [MapviewWidget].
///
class MapViewPage2 extends StatefulWidget {
  final MapFileData mapFileData;

  final Datastore? datastore;

  const MapViewPage2({Key? key, required this.mapFileData, this.datastore}) : super(key: key);

  @override
  MapViewPageState2 createState() => MapViewPageState2();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState2 extends State<MapViewPage2> {
  late DisplayModel displayModel;

  late SymbolCache symbolCache;

  late MarkerdemoDatastore markerdemoDatastore;

  // Shows additional infos about nodes and ways, may be confusing and slow
  final debug = false;

  @override
  void initState() {
    super.initState();

    if (widget.mapFileData.mapType == MAPTYPE.OFFLINE) {
      // create tiles (=bitmaps) twice the normal size (=256*256 pixels) and scale
      // it down by half when viewing them. This increases the resolution of the tiles.
      // Also consider to use MediaQuery.of(context).devicePixelRatio for an even
      // better resolution.
      displayModel = DisplayModel(deviceScaleFactor: 2, backgroundColor: 0xffB3DDFF);
    } else {
      // all online tiles are in 256*256 pixels size. So we set the tilesize to accordingly
      displayModel = DisplayModel(deviceScaleFactor: 2, tilesize: (256 / 2).round());
    }

    /// For the offline-maps we need a cache for all the tiny symbols in the map
    symbolCache = widget.mapFileData.relativePathPrefix != null
        ? FileSymbolCache(imageLoader: ImageRelativeLoader(relativePathPrefix: widget.mapFileData.relativePathPrefix!))
        : FileSymbolCache();
    markerdemoDatastore = MarkerdemoDatastore(symbolCache: symbolCache, displayModel: displayModel);
  }

  @override
  void dispose() {
    super.dispose();
    //markerdemoDatastore.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context) as PreferredSizeWidget,
      body: _buildMapViewBody(context),
    );
  }

  /// Constructs the [AppBar] of the [MapViewPage] page.
  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: Text(widget.mapFileData.displayedName),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (choice) => _handleMenuItemSelect(choice),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: "Debug",
              child: Text("Debug"),
            ),
          ],
        ),
      ],
    );
  }

  /// Executes the selected action of the popup menu.
  Future<void> _handleMenuItemSelect(String value) async {
    RenderTheme renderTheme = await RenderThemeBuilder.create(displayModel, widget.mapFileData.theme);
    switch (value) {
      case 'Debug':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => MapHeaderPage(widget.mapFileData, renderTheme),
          ),
        );
        break;
    }
  }

  /// Constructs the body ([FlutterMapView]) of the [MapViewPage].
  Widget _buildMapViewBody(BuildContext context) {
    return MapviewWidget(
        displayModel: displayModel,
        createMapModel: () async {
          /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
          return widget.mapFileData.mapType == MAPTYPE.OFFLINE ? await _createOfflineMapModel() : await _createOnlineMapModel();
        },
        createViewModel: () async {
          return _createViewModel();
        });
  }

  ViewModel _createViewModel() {
    // in this demo we use the markers only for offline databases.
    ViewModel viewModel = ViewModel(
      displayModel: displayModel,
      contextMenuBuilder: debug
          ? DebugContextMenuBuilder(datastore: widget.datastore!)
          : widget.mapFileData.mapType == MAPTYPE.OFFLINE
              ? MarkerdemoContextMenuBuilder()
              : const DefaultContextMenuBuilder(),
    );

    if (widget.mapFileData.indoorZoomOverlay)
      viewModel.addOverlay(IndoorlevelZoomOverlay(viewModel, indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel.addOverlay(ZoomOverlay(viewModel));
    viewModel.addOverlay(DistanceOverlay(viewModel));
    //viewModel.addOverlay(DemoOverlay(viewModel: viewModel));

    // set default position
    viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat, widget.mapFileData.initialPositionLong);
    viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    viewModel.observeMoveAroundStart.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerStart(event);
    });
    viewModel.observeMoveAroundCancel.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerCancel(event);
    });
    viewModel.observeMoveAroundUpdate.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerUpdate(event);
    });
    viewModel.observeMoveAroundEnd.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerEnd(event);
    });
    // used to demo the rotation-feature
    viewModel.addOverlay(RotationOverlay(viewModel));
    viewModel.addOverlay(RotationSliderOverlay(viewModel));
    return viewModel;
  }

  Future<MapModel> _createOfflineMapModel() async {
    /// Prepare the Themebuilder. This instructs the renderer how to draw the images
    RenderTheme renderTheme = await RenderThemeBuilder.create(displayModel, widget.mapFileData.theme);

    /// instantiate the job renderer. This renderer is the core of the system and renders the tile-bitmaps
    final JobRenderer jobRenderer = MapDataStoreRenderer(widget.datastore!, renderTheme, symbolCache, false);

    /// and now it is similar to online rendering.

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = await WebTileBitmapCache.create(jobRenderer.getRenderKey());
    } else {
      bitmapCache = await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
      symbolCache: symbolCache,
    );
    mapModel.markerDataStores.add(markerdemoDatastore);
    if (debug) mapModel.markerDataStores.add(DebugDatastore(symbolCache: symbolCache, displayModel: displayModel));

    return mapModel;
  }

  Future<MapModel> _createOnlineMapModel() async {
    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    JobRenderer jobRenderer = widget.mapFileData.mapType == MAPTYPE.OSM ? MapOnlineRendererWeb() : ArcGisOnlineRenderer();

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache.create();
    } else {
      bitmapCache = await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
    );
    return mapModel;
  }
}
