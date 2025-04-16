import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_example/mapfileanalyze/subfileparamspage.dart';
import 'package:mapsforge_example/mapfileanalyze/tagspage.dart';
import 'package:mapsforge_example/pathhandler.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

import '../map-file-data.dart';

///
/// These classes are for debugging purposes only.
///
class MapHeaderPage extends StatelessWidget {
  final MapFileData mapFileData;

  final RenderTheme renderTheme;

  MapHeaderPage(this.mapFileData, this.renderTheme);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return FutureBuilder(
      future: _loadMapFile(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.data == null)
          return const Center(
            child: const CircularProgressIndicator(),
          );
        MapFile mapFile = snapshot.data;
        return ListView(
          children: <Widget>[
            _buildGeneralCard(mapFile),
            _buildFileinfoCard(mapFile, context),
            _buildFileheaderCard(context, mapFile),
          ],
        );
      },
    );
  }

  Card _buildFileinfoCard(MapFile mapFile, BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Map fileinfo Properties",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LabeltextCustom(
                  label: "Zoomlevel",
                  value: "${mapFile.getMapFileInfo().zoomlevelRange.zoomlevelMin} - ${mapFile.getMapFileInfo().zoomlevelRange.zoomlevelMax}"),
              InkWell(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("SubfileParams: "),
                    Icon(Icons.more_horiz),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => SubfileParamsPage(
                        mapFile: mapFile,
                        subFileParameters: mapFile.getMapFileInfo().subFileParameters.values.toList(),
                        renderTheme: renderTheme,
                      ),
                    ),
                  );
                },
              ),
              // subFileParameters
            ],
          ),
        ],
      ),
    );
  }

  Card _buildGeneralCard(MapFile mapFile) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Mapfile General Properties",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //LabeltextCustom(label: "Filename", value: mapFile.filename),
              // _fileSize is private but only used to verify header and to check if read beyond file
              LabeltextCustom(label: "Zoomlevel", value: "${mapFile.zoomlevelRange}"),
              LabeltextCustom(label: "Timestamp", value: formatMsToDatetimeMs(mapFile.timestamp)),
            ],
          ),
        ],
      ),
    );
  }

  Card _buildFileheaderCard(BuildContext context, MapFile mapFile) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Map fileheader Properties",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LabeltextCustom(label: "Comment", value: mapFile.getMapHeaderInfo().comment),
              LabeltextCustom(label: "CreatedBy", value: mapFile.getMapHeaderInfo().createdBy),
              LabeltextCustom(label: "debugFile", value: "${mapFile.getMapHeaderInfo().debugFile}"),
              LabeltextCustom(label: "FileSize", value: "${mapFile.getMapHeaderInfo().fileSize}"),
              LabeltextCustom(label: "FileVersion", value: "${mapFile.getMapHeaderInfo().fileVersion}"),
              LabeltextCustom(label: "LanguagesPreferences", value: mapFile.getMapHeaderInfo().languagesPreference),
              LabeltextCustom(label: "MapTimestamp", value: formatMsToDatetimeMs(mapFile.getMapHeaderInfo().mapDate)),
              LabeltextCustom(label: "ProjectionName", value: mapFile.getMapHeaderInfo().projectionName),
              LabeltextCustom(label: "StartZoomLevel", value: "${mapFile.getMapHeaderInfo().startZoomLevel}"),
              LabeltextCustom(label: "StartPosition", value: "${formatLatLong(mapFile.getMapHeaderInfo().startPosition)}"),
              LabeltextCustom(label: "TilePixelSize", value: "${mapFile.getMapHeaderInfo().tilePixelSize}"),
              LabeltextCustom(
                  label: "Zoomlevel",
                  value: "${mapFile.getMapHeaderInfo().zoomlevelRange.zoomlevelMin} - ${mapFile.getMapHeaderInfo().zoomlevelRange.zoomlevelMax}"),
              LabeltextCustom(label: "Boundingbox", value: "${formatBoundingbox(mapFile.getMapHeaderInfo().boundingBox)}"),
              InkWell(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LabeltextCustom(label: "PoiTags", value: "${mapFile.getMapHeaderInfo().poiTags.length}"),
                    const Icon(Icons.more_horiz),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => TagsPage(
                        tags: mapFile.getMapHeaderInfo().poiTags,
                      ),
                    ),
                  );
                },
              ),
              InkWell(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LabeltextCustom(label: "WayTags", value: "${mapFile.getMapHeaderInfo().wayTags.length}"),
                    const Icon(Icons.more_horiz),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => TagsPage(
                        tags: mapFile.getMapHeaderInfo().wayTags,
                      ),
                    ),
                  );
                },
              ),

              LabeltextCustom(label: "numberOfSubFiles", value: "${mapFile.getMapHeaderInfo().numberOfSubFiles}"),
              // poiTags
              // wayTags
            ],
          ),
        ],
      ),
    );
  }

  Future<MapFile> _loadMapFile() async {
    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    MapFile mapFile = await MapFile.from(pathHandler.getPath(mapFileData.fileName), null, null);
    // to open the mapfile
    await mapFile.getBoundingBox();
    return mapFile;
  }

  String formatMsToDatetimeMs(int? ms) {
    if (ms == null) return "";
    if (ms == 0) return "";
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    var format = DateFormat("yyyy-MM-dd HH:mm:ss-SSS");
    return format.format(date);
  }

  String formatLatLong(ILatLong? latLong) {
    if (latLong == null) return "Unknown";
    return "${latLong.latitude.toStringAsPrecision(6)} / ${latLong.longitude.toStringAsPrecision(6)}";
  }

  String formatBoundingbox(BoundingBox boundingBox) {
    return "${boundingBox.maxLatitude.toStringAsPrecision(6)} / ${boundingBox.minLongitude.toStringAsPrecision(6)} - ${boundingBox.minLatitude.toStringAsPrecision(6)} / ${boundingBox.maxLongitude.toStringAsPrecision(6)}";
  }
}
