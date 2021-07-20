import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_archive/flutter_archive.dart' as filearchive;
import 'package:mapsforge_example/mapfileanalyze/mapheaderpage.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import 'map-file-data.dart';

class MapPageView extends StatefulWidget {
  final MapFileData mapFileData;

  const MapPageView({Key? key, required this.mapFileData}) : super(key: key);

  @override
  MapPageViewState createState() => MapPageViewState();
}

class MapPageViewState extends State<MapPageView>
    with SingleTickerProviderStateMixin {
  final BehaviorSubject<int> indoorLevelSubject =
      new BehaviorSubject<int>.seeded(0);

  double? downloadProgress;

  MapModel? mapModel;

  late ViewModel viewModel;

  late AnimationController fadeAnimationController;
  CurvedAnimation? fadeAnimation;

  final double toolbarSpacing = 15;

  GraphicFactory? _graphicFactory;

  @override
  void initState() {
    _prepare();

    fadeAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        value: 1,
        vsync: this,
        lowerBound: 0,
        upperBound: 1);
    fadeAnimation =
        CurvedAnimation(parent: fadeAnimationController, curve: Curves.ease);

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
                value: downloadProgress == null || downloadProgress == 1
                    ? null
                    : downloadProgress,
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                  child: Text(downloadProgress == null || downloadProgress == 1
                      ? "Loading"
                      : "Downloading ${(downloadProgress! * 100).round()}%")),
            ],
          ));
    }

    return Scaffold(
      appBar: _buildHead(context) as PreferredSizeWidget?,
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
                enabled: false,
                value: "current_zoom_level",
                child: Text(
                    "Zoom level: ${this.viewModel.mapViewPosition!.zoomLevel}")),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      FlutterMapView(
        mapModel: mapModel!,
        viewModel: viewModel,
        graphicFactory: _graphicFactory!,
      ),
      Positioned(
          bottom: toolbarSpacing,
          right: toolbarSpacing,
          top: toolbarSpacing,
          // this widget has an unbound width
          // left: toolbarSpacing,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: FadeTransition(
                      opacity: fadeAnimationController,
                      child: IndoorLevelBar(
                        indoorLevelSubject: indoorLevelSubject,
                        indoorLevels: {
                          5: null,
                          4: null,
                          3: null,
                          2: "OG2",
                          1: "OG1",
                          0: "EG",
                          -1: "UG1",
                          -2: null,
                          -3: null,
                          -4: null,
                          -5: null
                        },
                        width: 45,
                        fillColor: Colors.white,
                        elevation: 2.0,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      )),
                ),
                SizedBox(height: toolbarSpacing),
                RawMaterialButton(
                  onPressed: () {
                    viewModel.zoomIn();
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
                    viewModel.zoomOut();
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
    if (widget.mapFileData.onlinemap) {
      _graphicFactory = FlutterGraphicFactory();

      final DisplayModel displayModel = DisplayModel();
      JobRenderer jobRenderer = MapOnlineRendererWeb();
      TileBitmapCache bitmapCache = await MemoryTileBitmapCache();
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
      // attach indoor level stream to indoor change function
      //indoorLevelSubject.listen(viewModel.setIndoorLevel);
      downloadProgress = 1;
      setState(() {});
      return;
    } else {
      final MapDataStore mapDataStore = await _prepareOfflinemap();
      final SymbolCache symbolCache =
          FileSymbolCache(rootBundle, widget.mapFileData.relativePathPrefix);
      _graphicFactory = FlutterGraphicFactory();
      final DisplayModel displayModel = DisplayModel();
      final RenderThemeBuilder renderThemeBuilder =
          RenderThemeBuilder(_graphicFactory!, symbolCache, displayModel);
      final String content =
          await rootBundle.loadString(widget.mapFileData.theme);
      renderThemeBuilder.parseXml(content);
      final RenderTheme renderTheme = renderThemeBuilder.build();
      final JobRenderer jobRenderer = MapDataStoreRenderer(
          mapDataStore, renderTheme, _graphicFactory!, true);
      final TileBitmapCache bitmapCache;
      if (kIsWeb) {
        bitmapCache = MemoryTileBitmapCache();
      } else {
        bitmapCache =
            await FileTileBitmapCache.create(jobRenderer.getRenderKey());
      }

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
      // attach indoor level stream to indoor change function
      indoorLevelSubject.listen(viewModel.setIndoorLevel);

      /*MapModelHelper.onLevelChange.listen((levelMappings) {
      if (!fadeAnimationController.isAnimating) levelMappings == null ? fadeAnimationController.reverse() : fadeAnimationController.forward();
    });*/

      setState(() {});
    }
  }

  Future<MapFile> _prepareOfflinemap() async {
    if (kIsWeb) return _prepareOfflinemapForWeb();
    String filePath = await widget.mapFileData.getLocalFilePath();
    //print("Using $filePath");

    if (await widget.mapFileData.fileExists()) {
      downloadProgress = 1;
      if (filePath.endsWith(".zip")) {
        filePath = filePath.replaceAll(".zip", ".map");
      }
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

      try {
        if (filePath.endsWith(".zip")) {
          print("Unzipping $filePath");
          Directory dir = await getApplicationDocumentsDirectory();
          await filearchive.ZipFile.extractToDirectory(
              zipFile: File(filePath),
              destinationDir: dir,
              onExtracting: (zipEntry, progress) {
                setState(() {
                  downloadProgress = progress / 100;
                });
                return filearchive.ZipFileOperation.includeItem;
              });
          filePath = filePath.replaceAll(".zip", ".map");
        }
      } catch (e) {
        print("Unzip Error - ${e}");
      }
    }
    final MapFile mapFile = await MapFile.from(filePath, null, null);
    return mapFile;
  }

  Future<MapFile> _prepareOfflinemapForWeb() async {
    String filePath = widget.mapFileData.fileName;
    print("loading $filePath from ${widget.mapFileData.url}");
    Response<List<int>> response;
    try {
      Dio dio = Dio();
      response = await dio.get<List<int>>(
        widget.mapFileData.url,
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
      throw e;
    }

    List<int> content = response.data!;
    assert(content.length > 0);
    //print("content of $filePath has ${content.length} byte");

    try {
      if (filePath.endsWith(".zip")) {
        print("Unzipping $filePath");
        Archive archive = ZipDecoder().decodeBytes(content);
        for (ArchiveFile file in archive) {
          print("  Unzipping ${file.name}");
          content = file.content;
          assert(content.length > 0);
          break;
        }
        filePath = filePath.replaceAll(".zip", ".map");
      }
    } catch (e) {
      print("Unzip Error - ${e}");
      throw e;
    }

    final MapFile mapFile =
        await MapFile.using(Uint8List.fromList(content), null, null);
    return mapFile;
  }

  void _handleMenuItemSelect(String value, BuildContext context) {
    switch (value) {
      case 'start_location':
        this.viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
            widget.mapFileData.initialPositionLong);
        this.viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
        break;

      case 'analyse_mapfile':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) =>
                MapHeaderPage(widget.mapFileData)));
        break;
    }
  }
}
