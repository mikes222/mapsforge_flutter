import 'dart:async';

import 'package:complete_example/context_menu/my_context_menu.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/gesture.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/overlay.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';

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
  late final IsolatePoolManager _poolManager;
  late final MemoryPressureMonitor _memoryMonitor;
  late final EnhancedTaskQueue _taskQueue;

  bool _showPerformanceOverlay = false;
  String _performanceInfo = '';

  Future? _createModelFuture;

  late Marker marker;

  MarkerDatastore markerDatastore = DefaultMarkerDatastore(zoomlevelRange: const ZoomlevelRange.standard());

  MarkerDatastore debugDatastore = DefaultMarkerDatastore(zoomlevelRange: const ZoomlevelRange.standard());

  Datastore? datastore;

  MapModel? _mapModel;

  @override
  void initState() {
    super.initState();
    _initializeOptimizations();
    _startPerformanceMonitoring();
    _createMarker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FutureBuilder should NOT call the future directly because we would risk creating the model multiple times. Instead this is the first
    // time we can create the future AND having the context.
    print("new CreateModleFuture");
    _createModelFuture ??= createModel(context);
  }

  void _createMarker() {
    // marker = PolylineTextMarker(
    //   path: [
    //     LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //     LatLong(widget.configuration.location.centerLatitude + 0.001, widget.configuration.location.centerLongitude + 0.001),
    //     LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude + 0.001),
    //   ],
    //   caption: "PolylineTextMarker",
    //   fontSize: 20,
    // );

    marker = AreaMarker(
      key: "area",
      path: [
        LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
        LatLong(widget.configuration.location.centerLatitude + 0.001, widget.configuration.location.centerLongitude + 0.001),
        LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude + 0.001),
        LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
      ],
    );

    // marker = PolylineMarker(
    //   path: [
    //     LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //     LatLong(widget.configuration.location.centerLatitude + 0.001, widget.configuration.location.centerLongitude + 0.001),
    //   ],
    // );

    // marker = RectMarker(
    //   minLatLon: LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //   maxLatLon: LatLong(widget.configuration.location.centerLatitude + 0.001, widget.configuration.location.centerLongitude + 0.001),
    // )..addCaption(caption: "RectCaption");

    // marker = CaptionMarker(
    //   latLong: LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //   caption: 'PoiCaption',
    // );

    // marker = CircleMarker(
    //   latLong: LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //   fillColor: Colors.white.withAlpha(200).toARGB32(),
    // )..addCaption(caption: "IconMarker");

    // marker = IconMarker(
    //   latLong: LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //   iconData: Icons.accessibility,
    // )..addCaption(caption: "IconMarker");

    // marker = PoiMarker(
    //   src: "packages/dart_rendertheme/assets/symbols/viewpoint.svg",
    //   latLong: LatLong(widget.configuration.location.centerLatitude, widget.configuration.location.centerLongitude),
    //   rotateWithMap: true,
    // )..addCaption(caption: "PoiMarker");

    //markerDatastore.addMarker(marker);
  }

  void _initializeOptimizations() {
    _poolManager = IsolatePoolManager(maxIsolates: 4);
    _memoryMonitor = MemoryPressureMonitor();
    _taskQueue = EnhancedTaskQueue(maxParallel: 4);

    _memoryMonitor.startMonitoring();
  }

  void _startPerformanceMonitoring() {
    // Update performance info every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updatePerformanceInfo();
      } else {
        timer.cancel();
      }
    });
  }

  void _updatePerformanceInfo() {
    final memoryStats = _memoryMonitor.memoryStatistics;
    final poolStats = _poolManager.getStatistics();

    setState(() {
      _performanceInfo =
          '''
Memory Pressure: ${(memoryStats.memoryPressure * 100).toStringAsFixed(1)}%
Active Tasks: ${_taskQueue.runningCount}
Pool Workers: ${poolStats['totalWorkers']}
''';
    });
  }

  @override
  void dispose() {
    _memoryMonitor.dispose();
    _poolManager.shutdown();
    _taskQueue.cancel();
    // mapModel must be disposed after use
    _mapModel?.dispose();
    // disposing the symbolcache also frees a lot of memory
    SymbolCacheMgr().dispose();
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
          return Stack(
            children: [
              // move the map
              MoveGestureDetector(mapModel: mapModel),
              // rotates the map when two fingers are pressed and rotated
              RotationGestureDetector(mapModel: mapModel),
              // scales the map when two fingers are pressed and zoomed
              //ScaleGestureDetector(mapModel: mapModel),
              ScaleGestureDetector(mapModel: mapModel),
              // informs mapModel about short, long and double taps
              TapGestureDetector(mapModel: mapModel),
              // Shows tiles according to the current position
              TileView(mapModel: mapModel),
              // Shows labels (and rotate them) according to the current position (if the renderer supports it)
              if (mapModel.renderer.supportLabels()) LabelView(mapModel: mapModel),
              //SingleMarkerOverlay(mapModel: mapModel, marker: marker),
              MarkerDatastoreOverlay(mapModel: mapModel, datastore: markerDatastore),
              MarkerDatastoreOverlay(mapModel: mapModel, datastore: debugDatastore),
              // Shows a ruler with distance information in the left-bottom corner of the map
              DistanceOverlay(mapModel: mapModel),
              // Shows zoom-in and zoom-out buttons
              ZoomOverlay(mapModel: mapModel),
              // listens to double-click events (configurable) and zooms in
              ZoomInOverlay(mapModel: mapModel),
              // shows the indoorlevel zoom buttons
              IndoorlevelOverlay(mapModel: mapModel),
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
                    downloadFile: widget.downloadPath!,
                    datastore: datastore,
                  );
                },
              ),
              if (_showPerformanceOverlay) _buildPerformanceOverlay(),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<MapModel> createModel(BuildContext context) async {
    // find the device to pixel ratio end set the global property accordingly. This will shrink the tiles, requires to produce more tiles but makes the
    // map crispier.
    double ratio = MediaQuery.devicePixelRatioOf(context);
    MapsforgeSettingsMgr().setDeviceScaleFactor(ratio);

    Renderer renderer;
    if (widget.configuration.rendererType.isOffline) {
      /// Read the map from the assets folder. Since monaco is small, we can keep it in memory
      datastore = await MapFile.createFromFile(filename: widget.downloadPath!);

      // Read the rendertheme from the assets folder.
      String renderthemeString = await rootBundle.loadString(widget.configuration.renderTheme!.fileName);
      Rendertheme rendertheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

      // The renderer converts the compressed data from mapfile to images. The rendertheme defines how the data should be rendered (size, colors, etc).
      renderer = DatastoreRenderer(datastore!, rendertheme, false);
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

  Widget _buildPerformanceOverlay() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _performanceInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
