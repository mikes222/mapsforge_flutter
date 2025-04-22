import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/map-download-page.dart';
import 'package:mapsforge_example/map-view-page2.dart';
import 'package:mapsforge_flutter/core.dart';

import 'map-file-data.dart';

/// The route page showing up when starting the application.
///
/// The user can choose a map to open or clean up cache/storage.
class MapList extends StatelessWidget {
  final List<MapFileData> mapFileDataList;

  MapList(this.mapFileDataList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context) as PreferredSizeWidget,
      body: _buildBody(context),
    );
  }

  /// Constructs the [AppBar] of the [MapList] page.
  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: const Text('Rendering Examples'),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (choice) => _handleMenuItemSelect(choice),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: "clear_tile_cache",
              child: Text("Delete Tile Cache"),
            ),
            const PopupMenuItem<String>(
              value: "delete_map_files",
              child: const Text("Delete Map Files"),
            ),
          ],
        ),
      ],
    );
  }

  /// Constructs the list of map files of the [MapList] page.
  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: mapFileDataList.map((element) {
          return _buildCard(context, element.displayedName, () {
            if (element.mapType != MAPTYPE.OFFLINE) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => MapViewPage2(mapFileData: element),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => MapDownloadPage(mapFileData: element),
                ),
              );
            }
          });
        }).toList(),
      ),
    );
  }

  /// Constructs a clickable [Card] element.
  Card _buildCard(BuildContext context, String caption, action, [bool enabled = true]) {
    return Card(
      margin: const EdgeInsets.only(top: 7, bottom: 7),
      elevation: 4,
      child: ListTile(
        title: Text(
          caption,
          style: TextStyle(color: enabled ? Colors.black : Colors.grey),
        ),
        contentPadding: const EdgeInsets.fromLTRB(17, 5, 17, 5),
        onTap: enabled ? action : null,
        trailing: const Icon(Icons.arrow_forward_rounded),
      ),
    );
  }

  /// Executes the selected action of the popup menu.
  Future<void> _handleMenuItemSelect(String value) async {
    switch (value) {
      case 'clear_tile_cache':
        await FileTileBitmapCache.purgeAllCaches();
        MemoryTileBitmapCache.purgeAllCaches();
        break;
      case 'delete_map_files':
        List<String> paths = await (await FileMgr().getLocalPathHandler("")).getFiles();
        for (String path in paths) {
          if (await FileSystemEntity.isFile(path)) {
            await File(path).delete();
          }
        }
        break;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

/// A class that just contains information about a map file.
class MapInfo {
  final String? mapFileSource;
  final String? mapFile;
  final double? lat;
  final double? lon;

  MapInfo({this.mapFileSource, this.mapFile, this.lat, this.lon});
}
