import 'package:dio/dio.dart';
import 'package:mapsforge_example/mapfileanalyze/mapheaderpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_example/level-bar.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'package:rxdart/rxdart.dart';
import 'map-file-data.dart';

class MapPageView extends StatefulWidget {
  final MapFileData mapFileData;

  const MapPageView({Key key, @required this.mapFileData}) : super(key: key);

  @override
  MapPageViewState createState() => MapPageViewState();
}

class MapPageViewState extends State<MapPageView> with SingleTickerProviderStateMixin {
  final BehaviorSubject<int> indoorLevelSubject = new BehaviorSubject<int>.seeded(0);

  double downloadProgress;

  MapModel mapModel;

  AnimationController fadeAnimationController;
  CurvedAnimation fadeAnimation;

  final double toolbarSpacing = 15;

  @override
  void initState() {
    _prepare();

    fadeAnimationController =
        AnimationController(duration: const Duration(milliseconds: 200), value: 1, vsync: this, lowerBound: 0, upperBound: 1);
    fadeAnimation = CurvedAnimation(parent: fadeAnimationController, curve: Curves.ease);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (this.mapModel == null || this.downloadProgress != 1) {
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.mapFileData.name),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: downloadProgress == null || downloadProgress == 1 ? null : downloadProgress,
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                  child: Text(
                      downloadProgress == null || downloadProgress == 1 ? "Loading" : "Downloading ${(downloadProgress * 100).round()}%")),
            ],
          ));
    }

    return Scaffold(
      appBar: _buildHead(context),
      body: _buildBody(context),
    );
  }

  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: Text(widget.mapFileData.name),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: Offset(0, 50),
          onSelected: (choice) => _handleMenuItemSelect(choice, context),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: "start_location",
              child: Text("Back to Start"),
            ),
            PopupMenuItem<String>(
              value: "analyse_mapfile",
              child: Text("Analyse Mapfile"),
            ),
            PopupMenuItem<String>(
                enabled: false, value: "current_zoom_level", child: Text("Zoom level: ${this.mapModel.mapViewPosition.zoomLevel}")),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      FlutterMapView(mapModel: mapModel),
      Positioned(
          bottom: toolbarSpacing,
          right: toolbarSpacing,
          top: toolbarSpacing,
          // this widget has an unbound width
          // left: toolbarSpacing,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            Flexible(
              child: FadeTransition(
                opacity: fadeAnimationController,
                child: IndoorLevelBar(
                  indoorLevelSubject: indoorLevelSubject,
                  indoorLevels: {5: null, 4: null, 3: null, 2: "OG2", 1: "OG1", 0: "EG", -1: "UG1", -2: null, -3: null, -4: null, -5: null},
                  width: 45,
                  fillColor: Colors.white,
                  elevation: 2.0,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
            SizedBox(height: toolbarSpacing),
            RawMaterialButton(
              onPressed: () {
                mapModel.zoomIn();
              },
              elevation: 2.0,
              fillColor: Colors.white,
              child: Icon(Icons.add),
              padding: EdgeInsets.all(10.0),
              shape: CircleBorder(),
              constraints: BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(height: toolbarSpacing),
            RawMaterialButton(
              onPressed: () {
                mapModel.zoomOut();
              },
              elevation: 2.0,
              fillColor: Colors.white,
              child: Icon(Icons.remove),
              padding: EdgeInsets.all(10.0),
              shape: CircleBorder(),
              constraints: BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]))
    ]);
  }

  Future<void> _prepare() async {
    String filePath = await widget.mapFileData.getLocalFilePath();

    if (await widget.mapFileData.fileExists()) {
      downloadProgress = 1;
    } else {
      Dio dio = Dio();
      try {
        Response response = await dio.download(
          widget.mapFileData.url,
          filePath,
          onReceiveProgress: (int received, int total) {
            setState(() {
              downloadProgress = received / total;
            });
          },
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
        );
      } catch (e) {
        print("Download Error - ${e}");
      }
    }

    final MapFile mapFile = MapFile(filePath, null, null);
    await mapFile.init();
    //mapFile.debug();
    final MapDataStore mapDataStore = mapFile;
    final GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel();
    final SymbolCache symbolCache = FileSymbolCache(graphicFactory);
    final RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    final String content = await rootBundle.loadString(widget.mapFileData.theme);
    renderThemeBuilder.parseXml(content);
    final RenderTheme renderTheme = renderThemeBuilder.build();
    final JobRenderer jobRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, true);
    final FileTileBitmapCache bitmapCache = FileTileBitmapCache(jobRenderer.getRenderKey());

    mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: jobRenderer,
      symbolCache: symbolCache,
      tileBitmapCache: bitmapCache,
    );

    // set default position
    mapModel.setMapViewPosition(widget.mapFileData.initialPositionLat, widget.mapFileData.initialPositionLong);
    mapModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    // attach indoor level stream to indoor change function
    indoorLevelSubject.listen(mapModel.setIndoorLevel);

    /*MapModelHelper.onLevelChange.listen((levelMappings) {
      if (!fadeAnimationController.isAnimating) levelMappings == null ? fadeAnimationController.reverse() : fadeAnimationController.forward();
    });*/

    setState(() {});
  }

  void _handleMenuItemSelect(String value, BuildContext context) {
    switch (value) {
      case 'start_location':
        this.mapModel.setMapViewPosition(widget.mapFileData.initialPositionLat, widget.mapFileData.initialPositionLong);
        this.mapModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
        break;

      case 'analyse_mapfile':
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapHeaderPage(widget.mapFileData)));
        break;
    }
  }
}
