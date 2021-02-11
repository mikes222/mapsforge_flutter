import 'dart:async';
import 'dart:io';
import 'map-page-view.dart';
import 'package:flutter/material.dart';
import 'map-file-data.dart';
import 'package:path_provider/path_provider.dart';

class MapList extends StatelessWidget {
  final List<MapFileData> mapFileDataList;

  MapList(this.mapFileDataList, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context),
      body: _buildBody(context),
    );
  }

  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: const Text('Indoor Rendering Examples'),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: Offset(0,50),
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

  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      scrollDirection: Axis.vertical,
      itemCount: mapFileDataList.length,
      itemBuilder: (context, i) {
        MapFileData mapFileData = mapFileDataList[i];
        return Card(
          margin: EdgeInsets.only(top: 7, bottom: 7),
          elevation: 4,
          child: ListTile(
            title: Text(mapFileData.name),
            contentPadding: EdgeInsets.fromLTRB(17, 5, 17, 5),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapPageView(mapFileData: mapFileData)));
            },
            trailing: Icon(Icons.arrow_forward_rounded)
          ),
        );
      },
    );
  }

  Future<void> _handleMenuItemSelect (String value) async {
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