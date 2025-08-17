import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';

class PoiWayListPage extends StatelessWidget {
  final MapFile mapFile;

  final SubFileParameter subFileParameter;

  final RenderTheme renderTheme;

  const PoiWayListPage(
      {Key? key,
      required this.mapFile,
      required this.subFileParameter,
      required this.renderTheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return FutureBuilder<_PoiWayCount>(
        future: _readBlock(),
        builder: (BuildContext context, AsyncSnapshot<_PoiWayCount> snapshot) {
          if (snapshot.hasError || snapshot.error != null) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (snapshot.data == null)
            return const Center(child: CircularProgressIndicator());
          _PoiWayCount _poiWayCount = snapshot.data!;

          return Flex(direction: Axis.horizontal, children: [
            Expanded(child: _showPois(_poiWayCount.poiCounts)),
            Expanded(child: _showWays(_poiWayCount.wayCounts)),
          ]);
        });
  }

  Widget _showPois(List<_PoiCount> pois) {
    Tile tile = Tile(0, 0, subFileParameter.baseZoomLevel, 0);
    return pois.isEmpty
        ? const Text("No POIs")
        : ListView.builder(
            itemCount: pois.length,
            itemBuilder: (BuildContext context, int index) {
              _PoiCount _poiCount = pois.elementAt(index);
              NodeProperties nodeProperties = NodeProperties(_poiCount.poi);
              RenderthemeLevel renderthemeLevel =
                  renderTheme.prepareZoomlevel(tile.zoomLevel);
              List renderers = renderthemeLevel.matchNode(tile, nodeProperties);
              return Card(
                  child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeltextCustom(
                          label: "Count", value: "${_poiCount.count}"),
                      renderers.length > 0
                          ? LabeltextCustom(
                              label: "Renderers", value: "${renderers.length}")
                          : const Icon(Icons.warning_amber_outlined),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _poiCount.poi.tags
                        .map((e) => LabeltextCustom(
                              label: e.key ?? "unknown",
                              value: e.value,
                            ))
                        .toList(),
                  ),
                ],
              ));
            });
  }

  Widget _showWays(List<_WayCount> ways) {
    Tile tile = Tile(0, 0, subFileParameter.baseZoomLevel, 0);
    Tile tileMax = Tile(0, 0, subFileParameter.baseZoomLevel, 0);
    return ways.isEmpty
        ? const Text("No Ways")
        : ListView.builder(
            itemCount: ways.length,
            itemBuilder: (BuildContext context, int index) {
              _WayCount _wayCount = ways.elementAt(index);
              RenderthemeLevel renderthemeLevel =
                  renderTheme.prepareZoomlevel(tile.zoomLevel);
              List renderers = _wayCount.isClosedWay
                  ? renderthemeLevel.matchClosedWay(tile, _wayCount.way)
                  : renderthemeLevel.matchLinearWay(tile, _wayCount.way);
              if (renderers.length == 0)
                renderers = _wayCount.isClosedWay
                    ? renderthemeLevel.matchClosedWay(tileMax, _wayCount.way)
                    : renderthemeLevel.matchLinearWay(tileMax, _wayCount.way);
              return Card(
                  child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeltextCustom(
                          label: "Count", value: "${_wayCount.count}"),
                      renderers.length > 0
                          ? LabeltextCustom(
                              label: "Renderers", value: "${renderers.length}")
                          : const Icon(Icons.warning_amber_outlined),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _wayCount.way.tags
                        .map((e) => LabeltextCustom(
                              label: e.key ?? "unknown",
                              value: e.value,
                            ))
                        .toList(),
                  ),
                  const Spacer(),
                  _wayCount.isClosedWay
                      ? const Icon(Icons.circle_outlined)
                      : const SizedBox(),
                ],
              ));
            });
  }

  void _reducePois(DatastoreReadResult mapReadResult, List<_PoiCount> pois) {
    mapReadResult.pointOfInterests.forEach((mapPoi) {
      List<Tag> tags = [];
      mapPoi.tags.forEach((tag) {
        if (tag.key == "name")
          tags.add(const Tag("name", "xxx"));
        else if (tag.key == "ele")
          tags.add(const Tag("ele", "xxx"));
        else if (tag.key == "addr:housenumber")
          tags.add(const Tag("addr:housenumber", "xxx"));
        else
          tags.add(tag);
      });
      PointOfInterest newPoi = PointOfInterest(0, tags, const LatLong(0, 0));
      _PoiCount? _poiCount =
          pois.firstWhereOrNull((_PoiCount poi) => poi.compare(newPoi));
      if (_poiCount == null) {
        _poiCount = _PoiCount(newPoi);
        pois.add(_poiCount);
      }
      _poiCount.count++;
    });
  }

  void _reduceWays(DatastoreReadResult mapReadResult, List<_WayCount> ways) {
    mapReadResult.ways.forEach((mapWay) {
      List<Tag> tags = [];
      mapWay.tags.forEach((tag) {
        if (tag.key == "name")
          tags.add(const Tag("name", "xxx"));
        else if (tag.key == "height")
          tags.add(const Tag("height", "xxx"));
        else if (tag.key == "addr:housenumber")
          tags.add(const Tag("addr:housenumber", "xxx"));
        else if (tag.key == "building:levels")
          tags.add(const Tag("building:levels", "xxx"));
        else if (tag.key == "building:colour")
          tags.add(const Tag("building:colour", "xxx"));
        else if (tag.key == "roof:colour")
          tags.add(const Tag("roof:colour", "xxx"));
        else if (tag.key == "roof:levels")
          tags.add(const Tag("roof:levels", "xxx"));
        else if (tag.key == "roof:height")
          tags.add(const Tag("roof:height", "xxx"));
        else if (tag.key == "min_height")
          tags.add(const Tag("min_height", "xxx"));
        else if (tag.key == "id")
          tags.add(const Tag("id", "xxx"));
        else if (tag.key == "ele")
          tags.add(const Tag("ele", "xxx"));
        else if (tag.key == "ref") {
          // ignore this tag
        } else
          tags.add(tag);
      });
      bool isClosedWay = LatLongUtils.isClosedWay(mapWay.latLongs[0]);
      Way newWay = Way(mapWay.layer, tags, [], null);
      _WayCount? _wayCount = ways.firstWhereOrNull(
          (_WayCount poi) => poi.compare(newWay, isClosedWay));
      if (_wayCount == null) {
        _wayCount = _WayCount(newWay, isClosedWay);
        ways.add(_wayCount);
      }
      _wayCount.count++;
    });
  }

  Future<_PoiWayCount> _readBlock() async {
    try {
      ReadbufferFile readBufferMaster =
          ReadbufferFile((mapFile.readBufferSource as ReadbufferFile).filename);

      QueryParameters queryParameters = new QueryParameters();
      queryParameters.queryZoomLevel = subFileParameter.baseZoomLevel;
      MercatorProjection mercatorProjection =
          MercatorProjection.fromZoomlevel(subFileParameter.baseZoomLevel);
      _PoiWayCount _poiWayCount = _PoiWayCount();
      int step = 20;
      for (int x = subFileParameter.boundaryTileLeft;
          x < subFileParameter.boundaryTileRight;
          x += step) {
        for (int y = subFileParameter.boundaryTileTop;
            y < subFileParameter.boundaryTileBottom;
            y += step) {
          Tile upperLeft = Tile(x, y, subFileParameter.baseZoomLevel, 0);
          Tile lowerRight = Tile(
              min(x + step - 1, subFileParameter.boundaryTileRight),
              min(y + step - 1, subFileParameter.boundaryTileBottom),
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

          _reducePois(result, _poiWayCount.poiCounts);
          _reduceWays(result, _poiWayCount.wayCounts);
        }
      }
      _poiWayCount.poiCounts =
          _poiWayCount.poiCounts.sorted((a, b) => b.count - a.count);
      _poiWayCount.wayCounts =
          _poiWayCount.wayCounts.sorted((a, b) => b.count - a.count);

      return _poiWayCount;
    } catch (e, stacktrace) {
      print("${e.toString()}");
      print("${stacktrace.toString()}");
      throw e;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _PoiCount {
  final PointOfInterest poi;

  int count = 0;

  _PoiCount(this.poi);

  bool compare(PointOfInterest other) {
    return const IterableEquality<Tag>().equals(poi.tags, other.tags);
  }
}

/////////////////////////////////////////////////////////////////////////////

class _WayCount {
  final Way way;

  int count = 0;

  final bool isClosedWay;

  _WayCount(this.way, this.isClosedWay);

  bool compare(Way other, bool isClosedWay) {
    if (isClosedWay != this.isClosedWay) return false;
    return const IterableEquality<Tag>().equals(way.tags, other.tags);
  }
}

/////////////////////////////////////////////////////////////////////////////

class _PoiWayCount {
  List<_PoiCount> poiCounts = [];

  List<_WayCount> wayCounts = [];
}
