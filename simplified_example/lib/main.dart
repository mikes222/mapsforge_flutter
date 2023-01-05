import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MapModel mapModel;
  late ViewModel viewModel;

  final MarkerDataStore markerDataStore = MarkerDataStore();
  PoiMarker? marker;

  @override
  void dispose() {
    mapModel.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Load the mapfile which holds the openstreetmap® data
    final mapFile =
        await MapFile.from('C:/mapsforge/maps/berlin.map', null, null);

    // Create the cache for assets
    final symbolCache = FileSymbolCache();

    // Create the displayModel which defines and holds the view/display settings
    // like maximum zoomLevel.
    final displayModel = DisplayModel();

    // Create the render theme which specifies how to render the informations
    // from the mapfile.
    final renderTheme = await RenderThemeBuilder.create(
      displayModel,
      'assets/render_themes/defaultrender.xml',
    );

    // Create the Renderer
    final jobRenderer =
        MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

    // Glue everything together into two models.
    mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
    );

    // Add MarkerDataStore to hold added markers
    mapModel.markerDataStores.add(markerDataStore);

    viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(52.5211, 13.3905);
    viewModel.setZoomLevel(16);


    // Listen to longTap and add marker
    viewModel.observeLongTap.listen((event) async {
      if (marker != null) {
        markerDataStore.removeMarker(marker!);
      }

      marker = PoiMarker(
        displayModel: DisplayModel(),
        src: 'assets/icons/marker.svg',
        height: 64,
        width: 48,
        latLong: LatLong(event.latitude, event.longitude),
        alignment: Alignment.bottomCenter
      );

      await marker!.initResources(symbolCache);
      markerDataStore.addMarker(marker!);

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FlutterMapView(mapModel: mapModel, viewModel: viewModel);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
