import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'map-file-data.dart';

/// The [StatefulWidget] displaying the interactive map page.
///
/// Routing to this page requires a [MapFileData] object that shall be rendered.
/// This version is easier because the underlying MapViewWidget keeps care of creating and destroying the
/// mapModel and viewModel. Intended drawback is that you cannot directly access the viewmodel and mapmodel. It could
/// be done by attaching an Overlay to the viewModel. See [ZoomOverlay] for an example.
class MapViewPage2 extends StatefulWidget {
  final MapFileData mapFileData;

  final MapDataStore? mapFile;

  const MapViewPage2(
      {Key? key, required this.mapFileData, required this.mapFile})
      : super(key: key);

  @override
  MapViewPageState2 createState() => MapViewPageState2();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState2 extends State<MapViewPage2> {
  final DisplayModel displayModel = DisplayModel();

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
    );
  }

  /// Constructs the body ([FlutterMapView]) of the [MapViewPage].
  Widget _buildMapViewBody(BuildContext context) {
    return MapviewWidget(
        displayModel: displayModel,
        createMapModel: (GraphicFactory graphicFactory) async {
          /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
          return widget.mapFileData.isOnlineMap == ONLINEMAPTYPE.OFFLINE
              ? await _createOfflineMapModel(graphicFactory)
              : await _createOnlineMapModel();
        },
        createViewModel: () async {
          return _createViewModel();
        });
  }

  ViewModel _createViewModel() {
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel.addOverlay(IndoorlevelZoomOverlay(viewModel,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel.addOverlay(ZoomOverlay(viewModel));
    viewModel.addOverlay(DistanceOverlay(viewModel));

    // set default position
    viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    return viewModel;
  }

  Future<MapModel> _createOfflineMapModel(GraphicFactory graphicFactory) async {
    /// For the offline-maps we need a cache for all the tiny symbols in the map
    final SymbolCache symbolCache;
    if (kIsWeb) {
      symbolCache = MemorySymbolCache(bundle: rootBundle);
    } else {
      symbolCache =
          FileSymbolCache(rootBundle, widget.mapFileData.relativePathPrefix);
    }

    /// Prepare the Themebuilder. This instructs the renderer how to draw the images
    final RenderThemeBuilder renderThemeBuilder =
        RenderThemeBuilder(graphicFactory, symbolCache, displayModel);
    final String content =
        await rootBundle.loadString(widget.mapFileData.theme);
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    final JobRenderer jobRenderer = MapDataStoreRenderer(
        widget.mapFile!, renderTheme, graphicFactory, true);

    /// and now it is similar to online rendering.

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache.create();
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
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

  Future<MapModel> _createOnlineMapModel() async {
    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    JobRenderer jobRenderer =
        widget.mapFileData.isOnlineMap == ONLINEMAPTYPE.OSM
            ? MapOnlineRendererWeb()
            : ArcGisOnlineRenderer();

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache.create();
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
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
