import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

void main() {
  _initLogging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mapsforge simple example', home: MyHomePage());
  }
}

//////////////////////////////////////////////////////////////////////////////

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//////////////////////////////////////////////////////////////////////////////

class _MyHomePageState extends State<MyHomePage> {
  /// FutureBuilder should never call the method directly according to its documentation to avoid creating the model multiple times.
  Future? _createModelFuture;

  MapModel? _mapModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FutureBuilder should NOT call the future directly because we would risk creating the model multiple times. Instead this is the first
    // time we can create the future AND having the context.
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
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text('Mapsforge simple example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(border: BoxBorder.all(color: Colors.green)),
            // create a future widget to asynchronously create the necessary MapModel
            child: FutureBuilder(
              future: _createModelFuture,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.error != null) {
                  // an error occured, show it on screen
                  return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
                }
                if (snapshot.data != null) {
                  // cool we have already the MapModel so we can start the view
                  MapModel mapsforgeModel = snapshot.data;
                  return MapsforgeView(mapModel: mapsforgeModel);
                }
                // mapModel is still not availabe or no position defined
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<MapModel> createModel(BuildContext context) async {
    // find the device to pixel ratio end set the global property accordingly. This will shrink the tiles, requires to produce more tiles but makes the
    // map crispier.
    double ratio = MediaQuery.devicePixelRatioOf(context);
    MapsforgeSettingsMgr().setDeviceScaleFactor(ratio);

    /// Read the map from the assets folder. Since monaco is small, we can keep it in memory
    ByteData mapContent = await rootBundle.load("assets/monaco.map");
    Datastore datastore = await Mapfile.createFromContent(content: mapContent.buffer.asUint8List());

    // Now instantiate our mapModel. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range. MapModel must be disposed after use.
    _mapModel = await MapModelHelper.createOfflineMapModel(datastore: datastore, zoomlevelRange: const ZoomlevelRange(0, 21));

    // For demo purposes we set a position and zoomlevel here. Note that this information would come from e.g. a gps provider in the real world.
    // Note that the [MapsforgeView] is unable to show something unless there is a position set. Consider using the default position of the mapFile if you do not
    // have a position available.
    // See [MapModel.moveTo] and [MapModel.setCenter] for setting positions if there is already an initial position.
    MapPosition mapPosition = MapPosition(43.7399, 7.4262, 18);
    _mapModel!.setPosition(mapPosition);

    // For demo purposes we could zoom and rotate after each few seconds.
    // Future.delayed(const Duration(seconds: 15), () {
    //   mapModel.zoomIn();
    // });
    // Future.delayed(const Duration(seconds: 30), () {
    //   mapModel.rotateTo(20);
    // });
    return _mapModel!;
  }
}

/////////////////////////////////////////////////////////////////////////////

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
