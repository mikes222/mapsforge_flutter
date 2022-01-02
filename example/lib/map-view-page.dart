import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/mapfileanalyze/mapheaderpage.dart';
import 'package:mapsforge_example/pathhandler.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'map-file-data.dart';

/// The [StatefulWidget] displaying the interactive map page.
///
/// Routing to this page requires a [MapFileData] object that shall be rendered.
class MapViewPage extends StatefulWidget {
  final MapFileData mapFileData;

  const MapViewPage({Key? key, required this.mapFileData}) : super(key: key);

  @override
  MapViewPageState createState() => MapViewPageState();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState extends State<MapViewPage> {
  late ViewModel viewModel;
  double? downloadProgress;
  MapModel? mapModel;
  GraphicFactory? _graphicFactory;
  String? error;

  @override
  void initState() {
    // prepare the mapView async
    _prepare();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (this.mapModel == null || this.downloadProgress != 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mapFileData.displayedName),
        ),
        body: _buildDownloadProgressBody(),
      );
    }

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
                "Zoom level: ${this.viewModel.mapViewPosition!.zoomLevel}",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadProgressBody() {
    if (error != null) {
      return Center(
        child: Text(error!),
      );
    }
    return StreamBuilder<FileDownloadEvent>(
        stream: FileMgr().fileDownloadOberve,
        builder: (context, AsyncSnapshot<FileDownloadEvent> snapshot) {
          if (snapshot.data != null) {
            if (snapshot.data!.status == DOWNLOADSTATUS.ERROR) {
              return const Center(child: Text("Error while downloading file"));
            } else if (snapshot.data!.status == DOWNLOADSTATUS.FINISH) {
              if (snapshot.data!.content != null) {
                // file downloaded into memory (we are in kIsWeb
                _startPrepareOfflineMapForWeb(snapshot.data!.content!);
              } else {
                // file is here, hope that _prepareOfflineMap() is happy and prepares the map for us.
                _prepareOfflineMap();
              }
            } else
              downloadProgress = (snapshot.data!.count / snapshot.data!.total);
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: downloadProgress == null || downloadProgress == 1
                    ? null
                    : downloadProgress,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  downloadProgress == null || downloadProgress == 1
                      ? "Loading"
                      : "Downloading ${(downloadProgress! * 100).round()}%",
                ),
              ),
            ],
          );
        });
  }

  /// Constructs the body ([FlutterMapView]) of the [MapViewPage].
  Widget _buildMapViewBody(BuildContext context) {
    return FlutterMapView(
      mapModel: mapModel!,
      viewModel: viewModel,
      graphicFactory: _graphicFactory!,
    );
  }

  /// A helper function for a asynchronous [_initState].
  Future<void> _prepare() async {
    /// prepare the graphics factory. This class provides drawing functions
    _graphicFactory = const FlutterGraphicFactory();

    if (widget.mapFileData.isOnlineMap != ONLINEMAPTYPE.NO) {
      /// we use an onlinemap - either OSM or ArcGis
      await _prepareOnlinemap();
    } else {
      await _prepareOfflineMap();
    }
    return;
  }

  /// Prepares the online map. Since this is quite fast we do not update the progress information here
  Future<void> _prepareOnlinemap() async {
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
    viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel.addOverlay(IndoorlevelZoomOverlay(viewModel,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel.addOverlay(ZoomOverlay(viewModel));
    viewModel.addOverlay(DistanceOverlay(viewModel));
    downloadProgress = 1;
    // let the UI switch to map mode
    if (mounted) setState(() {});
  }

  /// Downloads and stores a locally non-existing [MapFile], or
  /// loads a locally existing one.
  Future<void> _prepareOfflineMap() async {
    String fileName = widget.mapFileData.fileName;

    if (kIsWeb) {
      // web mode does not support filesystems so we need to download to memory instead
      await FileMgr().downloadNow2(widget.mapFileData.url);
      return;
    }

    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    if (await pathHandler.exists(fileName)) {
      /// yeah, file is already here we can immediately start
      // if (filePath.endsWith(".zip")) {
      //   filePath = filePath.replaceAll(".zip", ".map");
      // }
      final MapFile mapFile = await MapFile.from(pathHandler.getPath(fileName), null, null);
      await _prepareOfflineMapWithExistingMapfile(mapFile);
    } else {
      // downloadFile returns BEFORE the actual file has been downloaded so do not wait here at all
      bool ok = await FileMgr()
          .downloadToFile2(widget.mapFileData.url, pathHandler.getPath(fileName));
      if (!ok) {
        error = "Error while putting the downloadrequest in the queue";
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _startPrepareOfflineMapForWeb(List<int> content) async {
    MapFile mapFile =
        await MapFile.using(Uint8List.fromList(content), null, null);
    await _prepareOfflineMapWithExistingMapfile(mapFile);
  }

  Future<void> _prepareOfflineMapWithExistingMapfile(
      MapDataStore mapDataStore) async {
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
    final RenderTheme renderTheme = renderThemeBuilder.build();

    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    final JobRenderer jobRenderer =
        MapDataStoreRenderer(mapDataStore, renderTheme, _graphicFactory!, true);

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
    viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel.addOverlay(IndoorlevelZoomOverlay(viewModel,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel.addOverlay(ZoomOverlay(viewModel));
    viewModel.addOverlay(DistanceOverlay(viewModel));
    downloadProgress = 1;
    // let the UI switch to map mode
    if (mounted) setState(() {});
  }

  /// Executes the selected action of the popup menu.
  void _handleMenuItemSelect(String value, BuildContext context) {
    switch (value) {
      case 'start_location':
        this.viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
            widget.mapFileData.initialPositionLong);
        this.viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
        break;

      case 'analyse_mapfile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                MapHeaderPage(widget.mapFileData),
          ),
        );
        break;
    }
  }
}
