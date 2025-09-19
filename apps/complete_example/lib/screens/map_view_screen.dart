import 'dart:async';
import 'dart:io';

import 'package:complete_example/context_menu/my_context_menu.dart';
import 'package:complete_example/marker/my_marker_datastore.dart';
import 'package:complete_example/widget/performance_widget.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/gesture.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/overlay.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/online_renderer.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class MapViewScreen extends StatefulWidget {
  final AppConfiguration configuration;

  final String? downloadPath;

  const MapViewScreen({super.key, required this.configuration, this.downloadPath});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

//////////////////////////////////////////////////////////////////////////////

class _MapViewScreenState extends State<MapViewScreen> {
  bool _showPerformanceOverlay = false;

  Future? _createModelFuture;

  late Marker marker;

  Datastore? datastore;

  MapModel? _mapModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FutureBuilder should NOT call the future directly because we would risk creating the model multiple times. Instead this is the first
    // time we can create the future AND having the context.
    print("new CreateModleFuture");
    _createModelFuture ??= createModel(context);
  }

  @override
  void dispose() {
    // mapModel must be disposed after use
    _mapModel?.dispose();
    // The following caches also may be disposed. If you intend to start a new map it may make sense to keep them for faster startup
    SymbolCacheMgr().dispose();
    ParagraphCacheMgr().dispose();
    PainterFactory().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.configuration.location.name} Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showPerformanceOverlay ? Icons.visibility_off : Icons.analytics),
            onPressed: () {
              setState(() {
                _showPerformanceOverlay = !_showPerformanceOverlay;
              });
            },
            tooltip: 'Toggle Performance Overlay',
          ),
        ],
      ),
      body: _buildMap(),
    );
  }

  Widget _buildMap() {
    return FutureBuilder(
      future: _createModelFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.error != null) {
          return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
        if (snapshot.data != null) {
          // cool we have already the MapModel so we can start the view
          MapModel mapModel = snapshot.data;

          // These datastores are recreated at each build(). In our demo the markers in the datastore will be gone.
          // In real life you would fetch the markers from the source.
          MarkerDatastore markerDatastore = MyMarkerDatastore(mapModel);
          MarkerDatastore debugDatastore = DefaultMarkerDatastore();

          return Stack(
            children: [
              GenericGestureDetector(mapModel: mapModel),
              // rotates the map when two fingers are pressed and rotated
              RotationGestureDetector(mapModel: mapModel),
              // scales the map when two fingers are pressed and zoomed
              ScaleGestureDetector(mapModel: mapModel),
              // Shows tiles according to the current position
              TileView(mapModel: mapModel),
              // Shows labels (and rotate them) according to the current position (if the renderer supports it)
              if (mapModel.renderer.supportLabels()) LabelView(mapModel: mapModel),
              //SingleMarkerOverlay(mapModel: mapModel, marker: marker),
              MarkerDatastoreOverlay(mapModel: mapModel, datastore: markerDatastore, zoomlevelRange: const ZoomlevelRange.standard()),
              MarkerDatastoreOverlay(mapModel: mapModel, datastore: debugDatastore, zoomlevelRange: const ZoomlevelRange.standard()),
              // Shows a ruler with distance information in the left-bottom corner of the map
              DistanceOverlay(mapModel: mapModel),
              // Shows zoom-in and zoom-out buttons
              ZoomOverlay(mapModel: mapModel),
              // listens to double-click events (configurable) and zooms in
              ZoomInOverlay(mapModel: mapModel),
              // shows additional overlays or custom overlays
              // shows the indoorlevel zoom buttons
              //              IndoorlevelOverlay(mapModel: mapModel),

              // listens to tap events (configurable) and shows a context menu (also configurable)
              ContextMenuOverlay(
                mapModel: mapModel,
                contextMenuBuilder: (info) {
                  return MyContextMenu(
                    info: info,
                    markerDatastore: markerDatastore,
                    debugDatastore: debugDatastore,
                    mapModel: mapModel,
                    configuration: widget.configuration,
                    downloadFile: widget.downloadPath,
                    datastore: datastore,
                  );
                },
              ),
              NoPositionOverlay(mapModel: mapModel),
              if (_showPerformanceOverlay) const PerformanceWidget(),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<MapModel> createModel(BuildContext context) async {
    // Hillshading needs resources from filesystem
    Directory directory = await getTemporaryDirectory();
    // configure a loader to read images from the filesystem for hillshading
    SymbolCacheMgr().addLoader("file:ele_res/", ImageFileLoader(pathPrefix: "${directory.path}/sicilia_oam/"));

    // find the device to pixel ratio end set the global property accordingly. This will shrink the tiles, requires to produce more tiles but makes the
    // map crispier.
    double ratio = MediaQuery.devicePixelRatioOf(context);
    MapsforgeSettingsMgr().setDeviceScaleFactor(ratio);

    Renderer renderer;
    if (widget.configuration.rendererType.isOffline) {
      /// Read the map from the assets folder. Since monaco is small, we can keep it in memory
      datastore = await Mapfile.createFromFile(filename: widget.downloadPath!.replaceAll(".zip", ".map"));

      // Read the rendertheme from the assets folder.
      String renderthemeString = await rootBundle.loadString(widget.configuration.renderTheme!.fileName);
      Rendertheme rendertheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

      // The renderer converts the compressed data from mapfile to images. The rendertheme defines how the data should be rendered (size, colors, etc).
      renderer = DatastoreRenderer(datastore!, rendertheme, useIsolateReader: !StorageMgr().isEnabled());
    } else if (widget.configuration.rendererType == RendererType.openStreetMap) {
      renderer = OsmOnlineRenderer();
    } else if (widget.configuration.rendererType == RendererType.arcGisMaps) {
      renderer = ArcgisOnlineRenderer();
    } else {
      throw UnimplementedError();
    }
    // Now instantiate our mapModel with the desired parameters. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range.
    // MapModel must be disposed after use.
    _mapModel = MapModel(renderer: renderer, zoomlevelRange: const ZoomlevelRange(0, 21));

    // For demo purposes we set a position and zoomlevel here. Note that this information would come from e.g. a gps provider in the real world.
    // Note that the map is unable to show something unless there is a position set. Consider using the default position of the mapFile.
    MapPosition mapPosition = MapPosition(
      widget.configuration.location.centerLatitude,
      widget.configuration.location.centerLongitude,
      widget.configuration.location.defaultZoomLevel,
    );
    _mapModel!.setPosition(mapPosition);

    return _mapModel!;
  }
}
