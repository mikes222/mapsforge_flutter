import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/map-view-page.dart';
import 'package:mapsforge_example/pathhandler.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

import 'map-file-data.dart';

/// The [StatefulWidget] which downloads the mapfile.
///
/// Routing to this page requires a [MapFileData] object that shall be rendered.
class MapDownloadPage extends StatefulWidget {
  final MapFileData mapFileData;

  const MapDownloadPage({Key? key, required this.mapFileData})
      : super(key: key);

  @override
  MapDownloadPageState createState() => MapDownloadPageState();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapDownloadPageState extends State<MapDownloadPage> {
  late ViewModel viewModel;
  double? downloadProgress;
  MapModel? mapModel;
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
          if (snapshot.data != null) {
            if (snapshot.data!.status == DOWNLOADSTATUS.ERROR) {
              return const Center(child: Text("Error while downloading file"));
            } else if (snapshot.data!.status == DOWNLOADSTATUS.FINISH) {
              if (snapshot.data!.content != null) {
                // file downloaded into memory (we are in kIsWeb
                _startMapWithContent(snapshot.data!.content!);
              } else {
                // file is here, hope that _prepareOfflineMap() is happy and prepares the map for us.
                _startMapWithFile();
              }
            } else
              downloadProgress = (snapshot.data!.count / snapshot.data!.total);
          } else {
            // let's start the download process
            _startDownload();
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: downloadProgress == null || downloadProgress == 1
                    ? null
                    : downloadProgress,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  downloadProgress == null || downloadProgress == 1
                      ? "Loading"
                      : "Downloading ${(downloadProgress! * 100).round()}%",
                ),
              ),
            ],
          );
        });
  }

  Future<void> _startDownload() async {
    if (widget.mapFileData.isOnlineMap != ONLINEMAPTYPE.OFFLINE) {
      // we want to show an online map. Nothing to download.
      Future.delayed(const Duration(seconds: 1), () {
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                MapViewPage(mapFileData: widget.mapFileData, mapFile: null),
          ),
        ));
      });
      return;
    }

    if (kIsWeb) {
      // web mode does not support filesystems so we need to download to memory instead
      await FileMgr().downloadNow2(widget.mapFileData.url);
      return;
    }

    String fileName = widget.mapFileData.fileName;
    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    if (await pathHandler.exists(fileName)) {
      // file already exists locally, start now
      await _startMapWithFile();
    } else {
      bool ok = await FileMgr().downloadToFile2(
          widget.mapFileData.url, pathHandler.getPath(fileName));
      if (!ok) {
        error = "Error while putting the downloadrequest in the queue";
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _startMapWithContent(List<int> content) async {
    MapFile mapFile =
        await MapFile.using(Uint8List.fromList(content), null, null);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            MapViewPage(mapFileData: widget.mapFileData, mapFile: mapFile),
      ),
    );
  }

  Future<void> _startMapWithFile() async {
    String fileName = widget.mapFileData.fileName;

    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    final MapFile mapFile =
        await MapFile.from(pathHandler.getPath(fileName), null, null);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            MapViewPage(mapFileData: widget.mapFileData, mapFile: mapFile),
      ),
    );
  }
}
