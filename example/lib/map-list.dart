import 'dart:async';
import 'dart:io';
import 'map-view-page.dart';
import 'package:flutter/material.dart';
import 'map-file-data.dart';
import 'package:path_provider/path_provider.dart';

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
          offset: Offset(0, 50),
          onSelected: (choice) => _handleMenuItemSelect(choice),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: "clear_tile_cache",
              child: Text("Delete Tile Cache"),
            ),
            PopupMenuItem<String>(
              value: "delete_map_files",
              child: Text("Delete Map Files"),
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => MapViewPage(mapFileData: element),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  /// Constructs a clickable [Card] element.
  Card _buildCard(BuildContext context, String caption, action, [bool enabled = true]) {
    return Card(
      margin: EdgeInsets.only(top: 7, bottom: 7),
      elevation: 4,
      child: ListTile(
        title: Text(
          caption,
          style: TextStyle(color: enabled ? Colors.black : Colors.grey),
        ),
        contentPadding: EdgeInsets.fromLTRB(17, 5, 17, 5),
        onTap: enabled ? action : null,
        trailing: Icon(Icons.arrow_forward_rounded),
      ),
    );
  }

  /// Executes the selected action of the popup menu.
  Future<void> _handleMenuItemSelect(String value) async {
    switch (value) {
      case 'clear_tile_cache':
        String fileCachePath = (await getTemporaryDirectory()).path + "/mapsforgetiles";
        var fileCacheDir = Directory(fileCachePath);
        if (await fileCacheDir.exists()) {
          fileCacheDir.list(recursive: false).forEach((f) async {
            f.delete(recursive: true);
          });
        }
        break;
      case 'delete_map_files':
        Directory dir = await getApplicationDocumentsDirectory();
        dir.list(recursive: false).forEach((f) async {
          if (await FileSystemEntity.isFile(f.path)) {
            f.delete();
          }
        });
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
