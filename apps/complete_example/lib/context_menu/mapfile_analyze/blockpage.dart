import 'package:complete_example/context_menu/mapfile_analyze/poipage.dart';
import 'package:complete_example/context_menu/mapfile_analyze/waypage.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';

class BlockPage extends StatelessWidget {
  final Mapfile mapFile;

  final SubFileParameter subFileParameter;

  const BlockPage({super.key, required this.mapFile, required this.subFileParameter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: List.generate(subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1, (idx) => idx + subFileParameter.zoomLevelMin).map((zoomlevel) {
        return FutureBuilder<DatastoreBundle?>(
          future: _readBlock(zoomlevel),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasError || snapshot.error != null) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (snapshot.data == null) return const Center(child: CircularProgressIndicator());
            DatastoreBundle datastoreBundle = snapshot.data;
            int? items = datastoreBundle.ways.length < 1000
                ? datastoreBundle.ways.fold<int>(
                    0,
                    ((previousValue, element) => previousValue + element.latLongs.fold(0, ((previousValue, element) => previousValue + element.length))),
                  )
                : null;

            return _CardWidget(datastoreBundle: datastoreBundle, items: items, zoomlevel: zoomlevel, minZoomlevel: subFileParameter.zoomLevelMin);
          },
        );
      }).toList(),
    );
  }

  Future<DatastoreBundle?> _readBlock(int zoomlevel) async {
    try {
      QueryParameters queryParameters = QueryParameters();
      queryParameters.queryZoomLevel = zoomlevel;
      MercatorProjection mercatorProjection = MercatorProjection.fromZoomlevel(subFileParameter.baseZoomLevel);
      Tile upperLeft = Tile(subFileParameter.boundaryTileLeft, subFileParameter.boundaryTileTop, subFileParameter.baseZoomLevel, 0);
      Tile lowerRight = Tile(subFileParameter.boundaryTileRight, subFileParameter.boundaryTileBottom, subFileParameter.baseZoomLevel, 0);
      queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
      queryParameters.calculateBlocks(subFileParameter);
      print("Querying Blocks from ${queryParameters.fromBlockX} - ${queryParameters.toBlockX} and ${queryParameters.fromBlockY} - ${queryParameters.toBlockY}");

      BoundingBox boundingBox = mercatorProjection.boundingBoxOfTiles(upperLeft, lowerRight);
      MapfileSelector selector = MapfileSelector.ALL;
      DatastoreBundle? result = await mapFile.processBlocks(mapFile.readBufferSource, queryParameters, subFileParameter, boundingBox, selector);
      //print("result: $result");
      return result;
    } catch (e, stacktrace) {
      print("${e.toString()}");
      print("${stacktrace.toString()}");
      rethrow;
    }
  }
}

class _CardWidget extends StatelessWidget {
  const _CardWidget({super.key, required this.datastoreBundle, required this.items, required this.zoomlevel, required this.minZoomlevel});

  final DatastoreBundle datastoreBundle;
  final int? items;
  final int minZoomlevel;
  final int zoomlevel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Zoomlevel ${minZoomlevel} - $zoomlevel", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("IsWater ${datastoreBundle.isWater}, "),
          InkWell(
            child: Row(children: <Widget>[Text("Pois ${datastoreBundle.pointOfInterests.length}, "), const Icon(Icons.more_horiz)]),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => PoiPage(pointOfInterests: datastoreBundle.pointOfInterests)));
            },
          ),
          InkWell(
            child: Row(
              children: <Widget>[Text("Ways ${datastoreBundle.ways.length}, sum ${items ?? "(not calculated)"} LatLongs, "), const Icon(Icons.more_horiz)],
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => WayPage(ways: datastoreBundle.ways)));
            },
          ),
        ],
      ),
    );
  }
}
