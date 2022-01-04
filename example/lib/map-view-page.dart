import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_example/mapfileanalyze/mapheaderpage.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'map-file-data.dart';

/// The [StatefulWidget] displaying the interactive map page.
///
/// Routing to this page requires a [MapFileData] object that shall be rendered.
class MapViewPage extends StatefulWidget {
  final MapFileData mapFileData;

  final MapDataStore? mapFile;

  const MapViewPage(
      {Key? key, required this.mapFileData, required this.mapFile})
      : super(key: key);

  @override
  MapViewPageState createState() => MapViewPageState();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState extends State<MapViewPage> {
  ViewModel? viewModel;
  MapModel? mapModel;
  GraphicFactory? _graphicFactory;
  RenderTheme? renderTheme;

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
          onSelected: (choice) => _handleMenuItemSelect(choice, context),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: "start_location",
              child: Text("Back to Start"),
            ),
            const PopupMenuItem<String>(
              value: "analyse_mapfile",
              child: Text("Analyse Mapfile"),
            ),
            PopupMenuItem<String>(
              enabled: false,
              value: "current_zoom_level",
              child: Text(
                "Zoom level: ${this.viewModel?.mapViewPosition?.zoomLevel}",
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constructs the body ([FlutterMapView]) of the [MapViewPage].
  Widget _buildMapViewBody(BuildContext context) {
    return FutureBuilder(
        future: widget.mapFileData.isOnlineMap == ONLINEMAPTYPE.OFFLINE
            ? _prepareOfflineMap(widget.mapFile!)
            : _prepareOnlinemap(),
        builder: (context, AsyncSnapshot snapshot) {
          if (viewModel == null) {
            // not yet prepared
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return FlutterMapView(
            mapModel: mapModel!,
            viewModel: viewModel!,
            graphicFactory: _graphicFactory!,
          );
        });
  }

  /// Prepares the online map. Since this is quite fast we do not update the progress information here
  Future<void> _prepareOnlinemap() async {
    /// prepare the graphics factory. This class provides drawing functions
    _graphicFactory = const FlutterGraphicFactory();

    /// prepare the display model. This class holds all properties for displaying the map
    final DisplayModel displayModel = DisplayModel();

    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    JobRenderer jobRenderer =
        widget.mapFileData.isOnlineMap == ONLINEMAPTYPE.OSM
            ? MapOnlineRendererWeb()
            : ArcGisOnlineRenderer();

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache();
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
    );
    viewModel = ViewModel(displayModel: mapModel!.displayModel);

    // set default position
    viewModel!.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel!.setZoomLevel(widget.mapFileData.initialZoomLevel);
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel!.addOverlay(IndoorlevelZoomOverlay(viewModel!,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel!.addOverlay(ZoomOverlay(viewModel!));
    viewModel!.addOverlay(DistanceOverlay(viewModel!));
  }

  Future<void> _prepareOfflineMap(MapDataStore mapDataStore) async {
    /// prepare the graphics factory. This class provides drawing functions
    _graphicFactory = const FlutterGraphicFactory();

    /// prepare the display model. This class holds all properties for displaying the map
    final DisplayModel displayModel = DisplayModel();

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
        RenderThemeBuilder(_graphicFactory!, symbolCache, displayModel);
    final String content =
        await rootBundle.loadString(widget.mapFileData.theme);
    renderThemeBuilder.parseXml(content);
    renderTheme = renderThemeBuilder.build();

    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    final JobRenderer jobRenderer = MapDataStoreRenderer(
        mapDataStore, renderTheme!, _graphicFactory!, true);

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache();
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
    );

    viewModel = ViewModel(displayModel: mapModel!.displayModel);

    // set default position
    viewModel!.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel!.setZoomLevel(widget.mapFileData.initialZoomLevel);
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel!.addOverlay(IndoorlevelZoomOverlay(viewModel!,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel!.addOverlay(ZoomOverlay(viewModel!));
    viewModel!.addOverlay(DistanceOverlay(viewModel!));
  }

  /// Executes the selected action of the popup menu.
  void _handleMenuItemSelect(String value, BuildContext context) {
    switch (value) {
      case 'start_location':
        this.viewModel!.setMapViewPosition(
            widget.mapFileData.initialPositionLat,
            widget.mapFileData.initialPositionLong);
        this.viewModel!.setZoomLevel(widget.mapFileData.initialZoomLevel);
        break;

      case 'analyse_mapfile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                MapHeaderPage(widget.mapFileData, renderTheme!),
          ),
        );
        break;
    }
  }
}
