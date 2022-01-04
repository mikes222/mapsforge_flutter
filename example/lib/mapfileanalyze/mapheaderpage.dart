import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_example/mapfileanalyze/subfileparamspage.dart';
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
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "General Properties",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LabeltextCustom(
                          label: "Filename", value: mapFile.filename),
                      // _fileSize is private but only used to verify header and to check if read beyond file
                      LabeltextCustom(
                          label: "Zoomlevel",
                          value:
                              "${mapFile.zoomLevelMin} - ${mapFile.zoomLevelMax}"),
                      LabeltextCustom(
                          label: "Timestamp",
                          value: formatMsToDatetimeMs(mapFile.timestamp)),
                    ],
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Map fileheader Properties",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LabeltextCustom(
                          label: "Zoomlevel",
                          value:
                              "${mapFile.getMapFileHeader().zoomLevelMinimum} - ${mapFile.getMapFileHeader().zoomLevelMaximum}"),
                      InkWell(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text("SubfileParams: "),
                            const Icon(Icons.more_horiz),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  SubfileParamsPage(
                                mapFile: mapFile,
                                subFileParameters: mapFile
                                    .getMapFileHeader()
                                    .subFileParameters
                                    .where((element) => element != null)
                                    .map((e) => e!)
                                    .toList(),
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
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Map Fileinfo Properties",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LabeltextCustom(
                          label: "Comment",
                          value: mapFile.getMapFileInfo().comment),
                      LabeltextCustom(
                          label: "CreatedBy",
                          value: mapFile.getMapFileInfo().createdBy),
                      LabeltextCustom(
                          label: "IncludeDebug",
                          value: "${mapFile.getMapFileInfo().debugFile}"),
                      LabeltextCustom(
                          label: "FileSize",
                          value: "${mapFile.getMapFileInfo().fileSize}"),
                      LabeltextCustom(
                          label: "FileVersion",
                          value: "${mapFile.getMapFileInfo().fileVersion}"),
                      LabeltextCustom(
                          label: "LanguagesPreferences",
                          value: mapFile.getMapFileInfo().languagesPreference),
                      LabeltextCustom(
                          label: "MapTimestamp",
                          value: formatMsToDatetimeMs(
                              mapFile.getMapFileInfo().mapDate)),
                      LabeltextCustom(
                          label: "ProjectionName",
                          value: mapFile.getMapFileInfo().projectionName),
                      LabeltextCustom(
                          label: "StartZoomLevel",
                          value: "${mapFile.getMapFileInfo().startZoomLevel}"),
                      LabeltextCustom(
                          label: "StartPosition",
                          value:
                              "${formatLatLong(mapFile.getMapFileInfo().startPosition)}"),
                      LabeltextCustom(
                          label: "TilePixelSize",
                          value: "${mapFile.getMapFileInfo().tilePixelSize}"),
                      LabeltextCustom(
                          label: "Zoomlevel",
                          value:
                              "${mapFile.getMapFileInfo().zoomLevelMin} - ${mapFile.getMapFileInfo().zoomLevelMax}"),
                      LabeltextCustom(
                          label: "Boundingbox",
                          value:
                              "${formatBoundingbox(mapFile.getMapFileInfo().boundingBox)}"),
                      LabeltextCustom(
                          label: "PoiTags",
                          value: "${mapFile.getMapFileInfo().poiTags.length}"),
                      LabeltextCustom(
                          label: "WayTags",
                          value: "${mapFile.getMapFileInfo().wayTags.length}"),
                      LabeltextCustom(
                          label: "numberOfSubFiles",
                          value:
                              "${mapFile.getMapFileInfo().numberOfSubFiles}"),
                      // poiTags
                      // wayTags
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<MapFile> _loadMapFile() async {
    PathHandler pathHandler = await FileMgr().getLocalPathHandler("");
    MapFile mapFile = await MapFile.from(
        pathHandler.getPath(mapFileData.fileName), null, null);
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
