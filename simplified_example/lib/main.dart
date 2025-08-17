import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/overlay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key) {
    _initLogging();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }

  /// Sets a [Logger] to log debug messages.
  void _initLogging() {
    // Print output to console.
    Logger.root.onRecord.listen((LogRecord r) {
      print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
    });

    // Root logger level.
    Logger.root.level = Level.FINEST;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Create the displayModel which defines and holds the view/display settings
  // like maximum zoomLevel.
  final displayModel = DisplayModel(deviceScaleFactor: 2);

  // Create the cache for assets
  final symbolCache = FileSymbolCache();

  // Bonus: A markerstore
  final MarkerDataStore markerDataStore = MarkerDataStore();

  Future<MapModel> _createMapModel() async {
    // Load the mapfile which holds the openstreetmap® data. Use either MapFile.from() or load it into memory first (small files only) and use MapFile.using()
    ByteData content = await rootBundle.load('assets/indoorUB-ext.map');
    final mapFile =
        await MapFile.using(content.buffer.asUint8List(), null, null);

    // Create the render theme which specifies how to render the informations
    // from the mapfile.
    final renderTheme = await RenderThemeBuilder.create(
      displayModel,
      'assets/render_themes/defaultrender.xml',
    );
    // Create the Renderer
    final jobRenderer = //DatastoreViewRenderer(
        //datastore: mapFile, renderTheme: renderTheme, symbolCache: symbolCache);
        MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

    // Glue everything together into two models, the mapModel here and the viewModel below.
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
    );

    // Bonus: Add MarkerDataStore to hold added markers
    mapModel.markerDataStores.add(markerDataStore);
    return mapModel;
  }

  Future<ViewModel> _createViewModel() async {
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    // set the initial position
    viewModel.setMapViewPosition(50.84, 12.93);
    // set the initial zoomlevel
    viewModel.setZoomLevel(16);
    // bonus feature: listen for long taps and add/remove a marker at the tap-positon
    viewModel.addOverlay(_MarkerOverlay(
      viewModel: viewModel,
      markerDataStore: markerDataStore,
      symbolCache: symbolCache,
      displayModel: displayModel,
    ));
    viewModel.addOverlay(ZoomOverlay(viewModel));
    return viewModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simplified example")),
      body: MapviewWidget(
        displayModel: displayModel,
        createMapModel: _createMapModel,
        createViewModel: _createViewModel,
      ),
    );
  }
}

/// Bonus: An overlay is just a normal widget which will be drawn on top of the map. In this case we do not
/// draw anything but just receive long tap events and add/remove a marker to the datastore. Take note
/// that the marker needs to be initialized (async) and afterwards added to the datastore and the
/// setRepaint() method is called to inform the datastore about changes so that it gets repainted
class _MarkerOverlay extends StatefulWidget {
  final MarkerDataStore markerDataStore;

  final ViewModel viewModel;

  final SymbolCache symbolCache;

  final DisplayModel displayModel;

  const _MarkerOverlay({
    required this.viewModel,
    required this.markerDataStore,
    required this.symbolCache,
    required this.displayModel,
  });

  @override
  State<StatefulWidget> createState() {
    return _MarkerOverlayState();
  }
}

class _MarkerOverlayState extends State {
  @override
  _MarkerOverlay get widget => super.widget as _MarkerOverlay;

  PoiMarker? _marker;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TapEvent>(
        stream: widget.viewModel.observeLongTap,
        builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
          if (snapshot.data == null) return const SizedBox();
          if (_marker != null) {
            widget.markerDataStore.removeMarker(_marker!);
          }

          _marker = PoiMarker(
            displayModel: widget.displayModel,
            src: 'assets/icons/marker.svg',
            height: 64,
            width: 48,
            latLong: snapshot.data!,
            position: Position.ABOVE,
          );

          _marker!.initResources(widget.symbolCache).then((value) {
            widget.markerDataStore.addMarker(_marker!);
            widget.markerDataStore.setRepaint();
          });

          return const SizedBox();
        });
  }
}
