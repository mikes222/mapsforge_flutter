import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

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
  late GraphicFactory graphicFactory;

  Future<void> _initialize() async {
    MapFile mapFile = await MapFile.from('/path/to/your.map', null, null);

    SymbolCache symbolCache = FileSymbolCache(rootBundle);

    graphicFactory = const FlutterGraphicFactory();

    DisplayModel displayModel = DisplayModel();

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, symbolCache, displayModel);
    String content = await rootBundle.loadString('assets/render_themes/defaultrender.xml');
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    
    MapDataStoreRenderer jobRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true);

    mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
    );

    viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(52.5220, 13.3917);
    viewModel.setZoomLevel(16);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FlutterMapView( mapModel: mapModel, viewModel: viewModel, graphicFactory: graphicFactory);
        } else {
          return const CircularProgressIndicator();
        }
    });
  }
}
