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

  const TileindexPage(
      {super.key, required this.subFileParameter, required this.mapFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: FutureBuilder(
          future: _readIndex(),
          builder: (context, snapshot) {
            if (snapshot.hasError || snapshot.error != null) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            if (snapshot.data == null)
              return const Center(
                child: CircularProgressIndicator(),
              );
            List<int> indexes = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: indexes
                    .map((indexEntry) => Card(
                          child: Column(
                            children: [
                              Text(
                                "Tile at 0x${(subFileParameter.startAddress + indexEntry).toRadixString(16)} (0x${indexEntry.toRadixString(16)})",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              FutureBuilder(
                                  future: _readTileHeader(
                                      indexes,
                                      indexEntry &
                                          MapFile.BITMASK_INDEX_OFFSET),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError ||
                                        snapshot.error != null) {
                                      print(snapshot.error);
                                      print(snapshot.stackTrace);
                                      return Text(snapshot.error
                                          .toString()
                                          .substring(0, 50));
                                    }
                                    if (snapshot.data == null)
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    List<Widget> widgets = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: widgets,
                                    );
                                  }),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
    );
  }

  Future<List<int>> _readIndex() async {
    ReadbufferFile readBufferMaster =
        ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);
    Readbuffer readBuffer = await readBufferMaster.readFromFileAt(
        subFileParameter.indexStartAddress,
        subFileParameter.indexEndAddress - subFileParameter.indexStartAddress);

    List<int> values = [];
    int idx = 0;
    for (int i = 0; i < readBuffer.getBufferSize() / 5; ++i) {
      int value =
          Deserializer.getFiveBytesLong(readBuffer.getBuffer(idx * 5, 5), 0);
      values.add(value);
      ++idx;
    }
    return values;
  }

  Future<List<Widget>> _readTileHeader(List<int> indexes, int offset) async {
    int index = indexes.indexOf(offset);
    int tilesPerRow = subFileParameter.boundaryTileRight -
        subFileParameter.boundaryTileLeft +
        1;
    int row = (index / tilesPerRow).floor();
    int column = index % tilesPerRow;
    double tileLatitude = subFileParameter.projection
        .tileYToLatitude((subFileParameter.boundaryTileTop + row));
    double tileLongitude = subFileParameter.projection
        .tileXToLongitude((subFileParameter.boundaryTileLeft + column));

    ReadbufferFile readBufferMaster =
        ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);
    Readbuffer readBuffer = await readBufferMaster.readFromFileAt(
        subFileParameter.startAddress + offset,
        subFileParameter.subFileSize - offset);
    List<Widget> res = [];
    if (mapFile.getMapHeaderInfo().debugFile)
      readBuffer.readUTF8EncodedString2(32);
    List<_Zoomtable> zoomtable = _readZoomtable(readBuffer);
    int poiCount = 0;
    int wayCount = 0;
    zoomtable.forEach((inner) {
      res.add(Text(
          "Zoomlevel: ${inner.zoomlevel}: Pois: ${inner.poiCount}, Ways: ${inner.wayCount}"));
      poiCount += inner.poiCount;
      wayCount += inner.wayCount;
    });
    int offsetToFirstWay = readBuffer.readUnsignedInt();
    res.add(
        Text("Offset to first way: 0x${offsetToFirstWay.toRadixString(16)}"));
    for (int i = 0; i < poiCount; ++i) {
      PointOfInterest pointOfInterest = mapFile.getMapfileHelper().read1Poi(
          readBuffer,
          tileLatitude,
          tileLongitude,
          mapFile,
          mapFile.getMapHeaderInfo().poiTags);
      res.add(Wrap(spacing: 10, children: [
        Text(
            "POI: Layer: ${pointOfInterest.layer}, tags: ${pointOfInterest.tags}"),
        Text(
            "${pointOfInterest.position.latitude}/${pointOfInterest.position.longitude}",
            style: TextStyle(fontSize: 10),
            maxLines: 5),
      ]));
    }
    // if (offsetToFirstWay > 0) {
    //   readBuffer.skipBytes(offsetToFirstWay);
    // }
    List<Way> ways = [];
    for (int i = 0; i < wayCount; ++i) {
      ways.addAll(mapFile.getMapfileHelper().read1Way(
          readBuffer,
          QueryParameters(),
          tileLatitude,
          tileLongitude,
          mapFile,
          mapFile.getMapHeaderInfo().wayTags,
          false,
          BoundingBox(0, 0, 0, 0),
          MapfileSelector.ALL));
    }
    int taglessWays = 0;
    for (Way way in ways) {
      if (way.tags.isEmpty) {
        ++taglessWays;
        continue;
      }
      res.add(Wrap(
        spacing: 10,
        children: [
          Text("Way: Layer: ${way.layer}, tags: ${way.tags}", maxLines: 5),
          Text(
            "${way.calculateBoundary()}",
            style: TextStyle(fontSize: 10),
            maxLines: 5,
          ),
        ],
      ));
    }
    if (taglessWays > 0) {
      res.add(Text("Ways without tags: $taglessWays"));
    }

    res.add(Text(
        "read 0x${readBuffer.getBufferPosition().toRadixString(16)} bytes"));
    return res;
  }

  List<_Zoomtable> _readZoomtable(Readbuffer readBuffer) {
    int rows =
        subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1;
    List<_Zoomtable> zoomTable = [];

    for (int row = 0; row < rows; ++row) {
      int cumulatedNumberOfPois = readBuffer.readUnsignedInt();
      int cumulatedNumberOfWays = readBuffer.readUnsignedInt();
      zoomTable.add(_Zoomtable(subFileParameter.zoomLevelMin + row,
          cumulatedNumberOfPois, cumulatedNumberOfWays));
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
