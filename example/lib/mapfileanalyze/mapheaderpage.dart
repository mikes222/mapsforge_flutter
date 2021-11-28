import 'package:mapsforge_example/filemgr.dart';
import 'package:mapsforge_example/mapfileanalyze/subfileparamspage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

import '../map-file-data.dart';

///
/// These classes are for debugging purposes only.
///
class MapHeaderPage extends StatelessWidget {
  final MapFileData mapFileData;

  MapHeaderPage(this.mapFileData);

  @override
  Widget build(BuildContext context) {
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
                    "Static Properties",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Wrap(
                  //   children: <Widget>[
                  //     Text("WayFilterEnabled: ${MapFile.wayFilterEnabled}, "),
                  //     Text("WayFilterDistance: ${MapFile.wayFilterDistance}, "),
                  //   ],
                  // ),
                ],
              ),
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "General Properties",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    children: <Widget>[
                      Text("Filename: ${mapFile.filename}, "),
                      // _fileSize is private but only used to verify header and to check if read beyond file
                      Text(
                          "Zoomlevel ${mapFile.zoomLevelMin} - ${mapFile.zoomLevelMax}, "),
                      Text(
                          "Timestamp ${formatMsToDatetimeMs(mapFile.timestamp)}, "),
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
                  Wrap(
                    children: <Widget>[
                      Text(
                          "Zoomlevel ${mapFile.getMapFileHeader().zoomLevelMinimum} - ${mapFile.getMapFileHeader().zoomLevelMaximum}, "),
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
                                    .subFileParameters,
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
                  Wrap(
                    children: <Widget>[
                      Text("Comment ${mapFile.getMapFileInfo().comment}, "),
                      Text("CreatedBy ${mapFile.getMapFileInfo().createdBy}, "),
                      Text(
                          "IncludeDebug ${mapFile.getMapFileInfo().debugFile}, "),
                      Text("FileSize ${mapFile.getMapFileInfo().fileSize}, "),
                      Text(
                          "FileVersion ${mapFile.getMapFileInfo().fileVersion}, "),
                      Text(
                          "LanguagesPreferences ${mapFile.getMapFileInfo().languagesPreference}, "),
                      Text(
                          "MapTimestamp ${formatMsToDatetimeMs(mapFile.getMapFileInfo().mapDate)}, "),
                      Text(
                          "ProjectionName ${mapFile.getMapFileInfo().projectionName}, "),
                      Text(
                          "StartZoomLevel ${mapFile.getMapFileInfo().startZoomLevel}, "),
                      Text(
                          "StartPosition ${formatLatLong(mapFile.getMapFileInfo().startPosition)}, "),
                      Text(
                          "TilePixelSize ${mapFile.getMapFileInfo().tilePixelSize}, "),
                      Text(
                          "Zoomlevel ${mapFile.getMapFileInfo().zoomLevelMin} - ${mapFile.getMapFileInfo().zoomLevelMax}, "),
                      Text(
                          "Boundingbox ${formatBoundingbox(mapFile.getMapFileInfo().boundingBox)}, "),
                      Text(
                          "PoiTags ${mapFile.getMapFileInfo().poiTags.length}, "),
                      Text(
                          "WayTags ${mapFile.getMapFileInfo().wayTags.length}, "),
                      Text(
                          "numberOfSubFiles ${mapFile.getMapFileInfo().numberOfSubFiles}, "),
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
    String _localFilePath = await FileMgr().findLocalPath();
    MapFile mapFile = await MapFile.from(_localFilePath, null, null);
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
