import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:leak_tracker/devtools_integration.dart';
// import 'package:leak_tracker/leak_tracker.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/map-view-page2.dart';
import 'package:mapsforge_example/pathhandler.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'map-file-data.dart';

/// The [StatefulWidget] which downloads the mapfile.
///
/// Routing to this page requires a [MapFileData] object that shall be rendered.
class MapDownloadPage extends StatefulWidget {
  final MapFileData mapFileData;

  const MapDownloadPage({Key? key, required this.mapFileData}) : super(key: key);

  @override
  MapDownloadPageState createState() => MapDownloadPageState();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapDownloadPageState extends State<MapDownloadPage> {
  double? downloadProgress;

  String? error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mapFileData.displayedName),
      ),
      body: _buildDownloadProgressBody(),
    );
  }

  Widget _buildDownloadProgressBody() {
    if (error != null) {
      return Center(
        child: Text(error!),
      );
    }
    return StreamBuilder<FileDownloadEvent>(
        stream: FileMgr().fileDownloadOberve,
        builder: (context, AsyncSnapshot<FileDownloadEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // let's start the download process
            _startDownload();
          } else {
            if (snapshot.data!.status == DOWNLOADSTATUS.ERROR) {
              return const Center(child: Text("Error while downloading file"));
            } else if (snapshot.data!.status == DOWNLOADSTATUS.FINISH) {
              downloadProgress = 1;
              _switchToMap(snapshot.data?.content);
            } else
              downloadProgress = (snapshot.data!.count / snapshot.data!.total);
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: downloadProgress == null || downloadProgress == 1 ? null : downloadProgress,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  downloadProgress == null || downloadProgress == 1 ? "Loading" : "Downloading ${(downloadProgress! * 100).round()} %",
                ),
              ),
            ],
          );
        });
  }

  Future<void> _startDownload() async {
    if (kIsWeb) {
      // web mode does not support filesystems so we need to download to memory instead
      await FileMgr().downloadNow2(widget.mapFileData.url);
      return;
    }

    String fileName = widget.mapFileData.fileName;
    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    if (await pathHandler.exists(fileName)) {
      // file already exists locally, start now
      final Datastore mapFile = await IsolateMapfile.create(pathHandler.getPath(fileName));
      //await MapFile.from(pathHandler.getPath(fileName), null, null);
      await _startMap(mapFile);
    } else if (widget.mapFileData.url.startsWith("http")) {
      bool ok = await FileMgr().downloadToFile2(widget.mapFileData.url, pathHandler.getPath(fileName));
      if (!ok) {
        error = "Error while putting the downloadrequest in the queue";
        if (mounted) setState(() {});
      }
    } else {
      ByteData data = await rootBundle.load(widget.mapFileData.url);
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(pathHandler.getPath(fileName)).writeAsBytes(bytes);
      final Datastore mapFile = await IsolateMapfile.create(pathHandler.getPath(fileName));
      await _startMap(mapFile);
    }
  }

  Future<void> _switchToMap(List<int>? content) async {
    if (content != null) {
      // file downloaded into memory
      MapFile mapFile = await MapFile.using(Uint8List.fromList(content), null, null);
      await _startMap(mapFile);
    } else {
      // file is here, hope that _prepareOfflineMap() is happy and prepares the map for us.
      String fileName = widget.mapFileData.fileName;

      PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
      final Datastore mapFile = await IsolateMapfile.create(pathHandler.getPath(fileName));
      await _startMap(mapFile);
    }
  }

  Future<void> _startMap(Datastore mapFile) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => MapViewPage2(mapFileData: widget.mapFileData, datastore: mapFile),
      ),
    );
    mapFile.dispose();
    // Timer(const Duration(seconds: 5), () {
    //   Leaks leaks = collectLeaks();
    //   leaks.notDisposed.forEach((LeakReport element) {
    //     print("Not disposed: ${element.toYaml("  ")}");
    //   });
    //   leaks.notGCed.forEach((element) {
    //     print("not gced: ${element.toYaml("  ")}");
    //   });
    // });
  }
}
