import 'dart:async';

import 'package:dart_common/model.dart';
import 'package:dart_common/src/performance_profiler.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_isolate/dart_isolate.dart';
import 'package:dart_mapfile/mapfile.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/cache/adaptive_memory_tile_cache.dart';
import 'package:mapsforge_view/src/cache/memory_pressure_monitor.dart';
import 'package:task_queue/task_queue.dart';

import '../models/app_models.dart';

class MapViewScreen extends StatefulWidget {
  final AppConfiguration configuration;

  const MapViewScreen({super.key, required this.configuration});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

//////////////////////////////////////////////////////////////////////////////

class _MapViewScreenState extends State<MapViewScreen> {
  late final PerformanceProfiler _profiler;
  late final GeometricIsolateWorker _isolateWorker;
  late final IsolatePoolManager _poolManager;
  late final MemoryPressureMonitor _memoryMonitor;
  late final AdaptiveMemoryTileCache _adaptiveCache;
  late final EnhancedTaskQueue _taskQueue;

  bool _showPerformanceOverlay = false;
  String _performanceInfo = '';

  Future? _createModelFuture;

  @override
  void initState() {
    super.initState();
    _initializeOptimizations();
    _startPerformanceMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FutureBuilder should NOT call the future directly because we would risk creating the model multiple times. Instead this is the first
    // time we can create the future AND having the context.
    _createModelFuture ??= createModel(context);
  }

  void _initializeOptimizations() {
    _profiler = PerformanceProfiler();
    _isolateWorker = GeometricIsolateWorker();
    _poolManager = IsolatePoolManager(maxIsolates: 4);
    _memoryMonitor = MemoryPressureMonitor();
    _adaptiveCache = AdaptiveMemoryTileCache.create(initialCapacity: 1000, memoryMonitor: _memoryMonitor);
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
    final memoryStats = _memoryMonitor.getMemoryStats();
    final cacheStats = _adaptiveCache.getStatistics();
    final poolStats = _poolManager.getStatistics();
    final report = _profiler.generateReport();

    setState(() {
      _performanceInfo =
          '''
Memory Pressure: ${(memoryStats['memoryPressure'] * 100).toStringAsFixed(1)}%
Cache Capacity: ${cacheStats['currentCapacity']}
Cache Utilization: ${(cacheStats['cacheUtilization'] * 100).toStringAsFixed(1)}%
Active Tasks: ${_taskQueue.runningCount}
Pool Workers: ${poolStats['totalWorkers']}
Profiler Events: ${report.totalEvents}
''';
    });
  }

  @override
  void dispose() {
    _memoryMonitor.dispose();
    _adaptiveCache.dispose();
    _poolManager.shutdown();
    _taskQueue.cancel();
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
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.of(context).pop(), tooltip: 'Back to Configuration'),
        ],
      ),
      body: _buildMap(),
      //      body: Stack(
      //        children: [
      //          _buildMapView(),
      //          if (_showPerformanceOverlay) _buildPerformanceOverlay(),
      //          _buildConfigurationInfo(),
      //        ],
      //      ),
    );
  }

  Widget _buildMap() {
    return FutureBuilder(
      future: _createModelFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.error != null) {
          // an error occured, show it on screen
          return Text("${snapshot.error}", style: TextStyle(color: Theme.of(context).colorScheme.error));
        }
        if (snapshot.data != null) {
          // cool we have already the MapModel so we can start the view
          MapModel mapsforgeModel = snapshot.data;
          return MapsforgeView(mapModel: mapsforgeModel);
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
      ByteData mapContent = await rootBundle.load("assets/monaco.map");
      MapFile mapFile = await MapFile.createFromContent(content: mapContent.buffer.asUint8List());

      // Read the rendertheme from the assets folder.
      String renderthemeString = await rootBundle.loadString(widget.configuration.renderTheme!.fileName);
      Rendertheme renderTheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

      // The renderer converts the compressed data from mapfile to images. The rendertheme defines how the data should be rendered (size, colors, etc).
      renderer = DatastoreRenderer(mapFile, renderTheme, false);
    } else if (widget.configuration.rendererType == RendererType.openStreetMap) {
      renderer = OsmOnlineRenderer();
    } else if (widget.configuration.rendererType == RendererType.arcGisMaps) {
      renderer = ArcgisOnlineRenderer();
    } else {
      throw UnimplementedError();
    }
    // Now instantiate our mapModel with the desired parameters. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range.
    MapModel mapModel = MapModel(renderer: renderer, zoomlevelRange: const ZoomlevelRange(0, 21));

    // For demo purposes we set a position and zoomlevel here. Note that this information would come from e.g. a gps provider in the real world.
    // Note that the map is unable to show something unless there is a position set. Consider using the default position of the mapFile.
    MapPosition mapPosition = MapPosition(
      widget.configuration.location.centerLatitude,
      widget.configuration.location.centerLongitude,
      widget.configuration.location.defaultZoomLevel,
    );
    mapModel.setPosition(mapPosition);

    // For demo purposes we could zoom and rotate after each few seconds.
    // Future.delayed(const Duration(seconds: 15), () {
    //   mapModel.zoomIn();
    // });
    // Future.delayed(const Duration(seconds: 30), () {
    //   mapModel.rotateTo(20);
    // });
    return mapModel;
  }

  Widget _buildMapView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.shade100, Colors.blue.shade300]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 120, color: Colors.blue.shade700),
            const SizedBox(height: 24),
            Text(
              'Map View Placeholder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'This is where the actual mapsforge map view would be rendered',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All performance optimizations are active and monitoring',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildConfigurationInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Configuration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildInfoRow('Renderer', widget.configuration.rendererType.displayName),
              if (widget.configuration.renderTheme != null) _buildInfoRow('Theme', widget.configuration.renderTheme!.displayName),
              _buildInfoRow('Location', widget.configuration.location.toString()),
              _buildInfoRow('Map File', widget.configuration.location.mapFileName),
              _buildInfoRow(
                'Coordinates',
                '${widget.configuration.location.centerLatitude.toStringAsFixed(4)}, ${widget.configuration.location.centerLongitude.toStringAsFixed(4)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
