import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/deserializer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';

class TileindexPage extends StatelessWidget {
  final SubFileParameter subFileParameter;

  final MapFile mapFile;

  final int maxItems = 80;

  final TextStyle infoStyle = const TextStyle(fontSize: 12, color: Colors.blueGrey);

  const TileindexPage({super.key, required this.subFileParameter, required this.mapFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tile Index"),
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: FutureBuilder(
          future: _readTileIndex(),
          builder: (context, snapshot) {
            if (snapshot.hasError || snapshot.error != null) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              );
            }
            if (snapshot.data == null)
              return const Center(
                child: CircularProgressIndicator(),
              );
            List<int> tileIndexes = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: tileIndexes.getRange(0, Math.min(200, tileIndexes.length)).map((indexEntry) => _buildTileCard(indexEntry, tileIndexes)).toList(),
              ),
            );
          }),
    );
  }

  Card _buildTileCard(int indexEntry, List<int> tileIndexes) {
    return Card(
      child: Column(
        children: [
          Text(
            "Tile at 0x${(subFileParameter.startAddress + indexEntry).toRadixString(16)}, (startAddress 0x${subFileParameter.startAddress.toRadixString(16)} + indexEntry 0x${indexEntry.toRadixString(16)})",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          FutureBuilder(
              future: _readTileHeader(tileIndexes, indexEntry & MapFile.BITMASK_INDEX_OFFSET),
              builder: (context, snapshot) {
                if (snapshot.hasError || snapshot.error != null) {
                  print(snapshot.error);
                  print(snapshot.stackTrace);
                  return Text(snapshot.error.toString(), style: const TextStyle(fontSize: 12, color: Colors.red));
                }
                if (snapshot.data == null)
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                List<Widget> widgets = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widgets,
                );
              }),
        ],
      ),
    );
  }

  /// Reads the tileIndexes for a subfile. Each index has 5 byte and points to the
  /// beginning of a tile.
  Future<List<int>> _readTileIndex() async {
    ReadbufferFile readBufferMaster = ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);
    Readbuffer readBuffer =
        await readBufferMaster.readFromFileAt(subFileParameter.indexStartAddress, subFileParameter.indexEndAddress - subFileParameter.indexStartAddress);

    List<int> values = [];
    int idx = 0;
    for (int i = 0; i < readBuffer.getBufferSize() / 5; ++i) {
      int value = Deserializer.getFiveBytesLong(readBuffer.getBuffer(idx * 5, 5), 0);
      values.add(value);
      ++idx;
    }
    return values;
  }

  Future<List<Widget>> _readTileHeader(List<int> indexes, int offset) async {
    int index = indexes.indexOf(offset);
    int tilesPerRow = subFileParameter.boundaryTileRight - subFileParameter.boundaryTileLeft + 1;
    int row = (index / tilesPerRow).floor();
    int column = index % tilesPerRow;
    double tileLatitude = subFileParameter.projection.tileYToLatitude((subFileParameter.boundaryTileTop + row));
    double tileLongitude = subFileParameter.projection.tileXToLongitude((subFileParameter.boundaryTileLeft + column));

    int nextOffset = index + 1 == subFileParameter.numberOfBlocks ? subFileParameter.subFileSize : indexes[index + 1];

    ReadbufferFile readBufferMaster = ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);
    Readbuffer readBuffer = await readBufferMaster.readFromFileAt(subFileParameter.startAddress + offset, nextOffset - offset);
    List<Widget> res = [];
    if (mapFile.getMapHeaderInfo().debugFile) readBuffer.readUTF8EncodedString2(32);
    List<_Zoomtable> zoomtable = _readZoomtable(readBuffer);
    Map<int, int> poiCounts = {};
    Map<int, int> wayCounts = {};
    zoomtable.forEach((inner) {
      res.add(Text("Zoomlevel: ${inner.zoomlevel}: Pois: ${inner.poiCount}, Ways: ${inner.wayCount}"));
      poiCounts[inner.zoomlevel] = inner.poiCount;
      wayCounts[inner.zoomlevel] = inner.wayCount;
    });
    int offsetToFirstWay = readBuffer.readUnsignedInt();
    res.add(Text("Offset to first way: 0x${offsetToFirstWay.toRadixString(16)}"));
    int taglessPois = 0;
    poiCounts.forEach((zoomlevel, poicount) {
      for (int i = 0; i < Math.min(maxItems, poicount); ++i) {
        PointOfInterest pointOfInterest =
            mapFile.getMapfileHelper().read1Poi(readBuffer, tileLatitude, tileLongitude, mapFile, mapFile.getMapHeaderInfo().poiTags);
        if (pointOfInterest.tags.isEmpty) {
          ++taglessPois;
        } else {
          res.add(Wrap(spacing: 10, children: [
            Text("Zoomlelel: $zoomlevel, POI: Layer: ${pointOfInterest.layer}, tags: ${pointOfInterest.printTags()}"),
            Text("${pointOfInterest.position.latitude.toStringAsFixed(6)}/${pointOfInterest.position.longitude.toStringAsFixed(6)}",
                style: const TextStyle(fontSize: 10), maxLines: 5),
          ]));
        }
      }
      if (maxItems < poicount) res.add(Text("${poicount - maxItems} more items", style: infoStyle));
    });
    if (taglessPois > 0) {
      res.add(Text("Pois without tags: $taglessPois"));
    }
    // if (offsetToFirstWay > 0) {
    //   readBuffer.skipBytes(offsetToFirstWay);
    // }
    int taglessWays = 0;
    wayCounts.forEach((zoomlevel, waycount) {
      for (int i = 0; i < Math.min(maxItems, waycount); ++i) {
        int pos = readBuffer.getBufferPosition();
        try {
          List<Way> newWays = mapFile.getMapfileHelper().read1Way(readBuffer, QueryParameters(), tileLatitude, tileLongitude, mapFile,
              mapFile.getMapHeaderInfo().wayTags, false, const BoundingBox(0, 0, 0, 0), MapfileSelector.ALL);
          newWays.forEachIndexed((index, way) {
            if (way.tags.isEmpty) {
              ++taglessWays;
              return;
            } else {
              res.add(Wrap(
                spacing: 10,
                children: [
                  Text(
                      "$i, $index, 0x${(subFileParameter.startAddress + offset + pos).toRadixString(16)}: Zoomlelel: $zoomlevel, ${LatLongUtils.isClosedWay(way.latLongs[0]) ? "Closed" : "Open"}Way: Layer: ${way.layer}, latLongs: ${way.latLongs.map((toElement) => toElement.length).toList()}, tags: ${way.printTags()}",
                      maxLines: 5),
                  Text(
                    "${way.getBoundingBox()}",
                    style: const TextStyle(fontSize: 10),
                    maxLines: 5,
                  ),
                ],
              ));
            }
          });
        } catch (error, stacktrace) {
          print(error);
          print(stacktrace);
          res.add(Text("Error ${error.toString()} while reading way $i from position 0x${(subFileParameter.startAddress + offset + pos).toRadixString(16)}",
              style: const TextStyle(fontSize: 12, color: Colors.red)));
        }
      }
      if (maxItems < waycount) res.add(Text("${waycount - maxItems} more items", style: infoStyle));
    });
    if (taglessWays > 0) {
      res.add(Text("Ways without tags: $taglessWays"));
    }

    int countPoi = zoomtable.fold(0, (idx, combine) => idx + combine.poiCount);
    int countWay = zoomtable.fold(0, (idx, combine) => idx + combine.wayCount);
    res.add(Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (countPoi > 0) Text("Bytes per poi: ${(offsetToFirstWay / countPoi).toStringAsFixed(1)}", style: infoStyle),
        if (countWay > 0) Text("Bytes per way: ${((readBuffer.getBufferPosition() - offsetToFirstWay) / countWay).toStringAsFixed(1)}", style: infoStyle),
        Text("read ${readBuffer.getBufferPosition()} bytes", style: infoStyle)
      ],
    ));
    return res;
  }

  List<_Zoomtable> _readZoomtable(Readbuffer readBuffer) {
    int rows = subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1;
    List<_Zoomtable> zoomTable = [];

    for (int row = 0; row < rows; ++row) {
      int cumulatedNumberOfPois = readBuffer.readUnsignedInt();
      int cumulatedNumberOfWays = readBuffer.readUnsignedInt();
      zoomTable.add(_Zoomtable(subFileParameter.zoomLevelMin + row, cumulatedNumberOfPois, cumulatedNumberOfWays));
    }

    return zoomTable;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Zoomtable {
  final int zoomlevel;
  final int poiCount;
  final int wayCount;

  _Zoomtable(this.zoomlevel, this.poiCount, this.wayCount);
}
