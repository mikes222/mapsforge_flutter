import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_mapfile/mapfile.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';

void main() {
  _initLogging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Mapsforge simple example', home: MyHomePage());
  }
}

//////////////////////////////////////////////////////////////////////////////

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

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
              future: createModel(context),
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
                // mapModel is still not availabe
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
    ByteData mapContent = await rootBundle.load("monaco.map");
    MapFile mapFile = await MapFile.createFromContent(content: mapContent.buffer.asUint8List());

    // Read the rendertheme from the assets folder.
    String renderthemeString = await rootBundle.loadString("defaultrender.xml");
    Rendertheme renderTheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

    // Now instantiate our mapModel with the desired parameters. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range.
    DatastoreRenderer renderer = DatastoreRenderer(mapFile, renderTheme, false);
    MapModel mapModel = MapModel(renderer: renderer, zoomlevelRange: const ZoomlevelRange(0, 21));

    // For demo purposes we set a position and zoomlevel here. Note that this information would come from e.g. a gps provider in the real world.
    // Note that the map is unable to show something unless there is a position set. Consider using the default position of the mapFile.
    MapPosition mapPosition = MapPosition(43.7399, 7.4262, 18);
    mapModel.setPosition(mapPosition);

    // For demo purposes we will zoom and rotate after each few seconds.
    // Future.delayed(const Duration(seconds: 15), () {
    //   mapModel.zoomIn();
    // });
    // Future.delayed(const Duration(seconds: 30), () {
    //   mapModel.rotateTo(20);
    // });
    return mapModel;
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
