import 'package:flutter/material.dart';
import 'package:mapsforge_example/mapfileanalyze/poipage.dart';
import 'package:mapsforge_example/mapfileanalyze/waypage.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';

class BlockPage extends StatelessWidget {
  final MapFile mapFile;

  final SubFileParameter subFileParameter;

  const BlockPage(
      {Key? key, required this.mapFile, required this.subFileParameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return FutureBuilder<DatastoreReadResult?>(
      future: _readBlock(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasError || snapshot.error != null) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        if (snapshot.data == null)
          return const Center(
            child: CircularProgressIndicator(),
          );
        DatastoreReadResult mapReadResult = snapshot.data;
        int? items = mapReadResult.ways.length < 1000
            ? mapReadResult.ways.fold<int>(
                0,
                ((previousValue, element) =>
                    previousValue +
                    element.latLongs.fold(
                      0,
                      ((previousValue, element) =>
                          previousValue + element.length),
                    )))
            : null;
        return ListView(
          children: <Widget>[
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("IsWater ${mapReadResult.isWater}, "),
                  InkWell(
                    child: Row(
                      children: <Widget>[
                        Text("Pois ${mapReadResult.pointOfInterests.length}, "),
                        const Icon(Icons.more_horiz),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => PoiPage(
                            pointOfInterests: mapReadResult.pointOfInterests,
                          ),
                        ),
                      );
                    },
                  ),
                  InkWell(
                    child: Row(
                      children: <Widget>[
                        Text(
                            "Ways ${mapReadResult.ways.length}, sum ${items ?? "(not calculated)"} LatLongs, "),
                        const Icon(Icons.more_horiz),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              WayPage(ways: mapReadResult.ways),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<DatastoreReadResult?> _readBlock() async {
    try {
      ReadbufferFile readBufferMaster =
          ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);

      QueryParameters queryParameters = new QueryParameters();
      queryParameters.queryZoomLevel = subFileParameter.baseZoomLevel;
      MercatorProjection mercatorProjection =
          MercatorProjection.fromZoomlevel(subFileParameter.baseZoomLevel);
      Tile upperLeft = Tile(subFileParameter.boundaryTileLeft,
          subFileParameter.boundaryTileTop, subFileParameter.baseZoomLevel, 0);
      Tile lowerRight = Tile(
          subFileParameter.boundaryTileRight,
          subFileParameter.boundaryTileBottom,
          subFileParameter.baseZoomLevel,
          0);
      queryParameters.calculateBaseTiles(
          upperLeft, lowerRight, subFileParameter);
      queryParameters.calculateBlocks(subFileParameter);
      print(
          "Querying Blocks from ${queryParameters.fromBlockX} - ${queryParameters.toBlockX} and ${queryParameters.fromBlockY} - ${queryParameters.toBlockY}");

      BoundingBox boundingBox =
          mercatorProjection.boundingBoxOfTiles(upperLeft, lowerRight);
      MapfileSelector selector = MapfileSelector.ALL;
      DatastoreReadResult? result = await mapFile.processBlocks(
        readBufferMaster,
        queryParameters,
        subFileParameter,
        boundingBox,
        selector,
      );
      //print("result: $result");
      return result;
    } catch (e, stacktrace) {
      print("${e.toString()}");
      print("${stacktrace.toString()}");
      throw e;
    }
  }
}
