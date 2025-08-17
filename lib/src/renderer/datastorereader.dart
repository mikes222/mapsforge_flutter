import 'package:mapsforge_flutter/src/model/maprectangle.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/wayproperties.dart';

class DatastoreReaderIsolate {
  static DatastoreReader? _reader;

  @pragma('vm:entry-point')
  static Future<RenderContext?> read(
      DatastoreReaderIsolateRequest request) async {
    _reader ??= DatastoreReader();
    return _reader!.read(request.datastore, request.tile,
        request.renderthemeLevel, request.maxLevels);
  }

  @pragma('vm:entry-point')
  static Future<RenderContext?> readLabels(
      DatastoreReaderIsolateRequest request) async {
    _reader ??= DatastoreReader();
    return _reader!.readLabels(request.datastore, request.tile,
        request.renderthemeLevel, request.maxLevels);
  }
}

//////////////////////////////////////////////////////////////////////////////

class DatastoreReaderIsolateRequest {
  final Datastore datastore;
  final Tile tile;
  final RenderthemeLevel renderthemeLevel;
  final int maxLevels;

  DatastoreReaderIsolateRequest(
      this.datastore, this.tile, this.renderthemeLevel, this.maxLevels);
}

//////////////////////////////////////////////////////////////////////////////

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread.
class DatastoreReader {
  DatastoreReader();

  Future<RenderContext?> read(Datastore datastore, Tile tile,
      RenderthemeLevel renderthemeLevel, int maxLevels) async {
    // read the mapdata directly in this thread
    RenderContext renderContext = RenderContext(tile, maxLevels);
    if (!(await datastore.supportsTile(tile))) {
      return null;
    }
    DatastoreReadResult? mapReadResult =
        await datastore.readMapDataSingle(tile);
    if (mapReadResult == null) {
      return null;
    }
    processMapReadResult(renderContext, tile, renderthemeLevel, mapReadResult);
    return renderContext;
  }

  Future<RenderContext?> readLabels(Datastore datastore, Tile tile,
      RenderthemeLevel renderthemeLevel, int maxLevels) async {
    RenderContext renderContext = RenderContext(tile, maxLevels);
    if (!(await datastore.supportsTile(tile))) {
      return null;
    }
    DatastoreReadResult? mapReadResult = await datastore.readLabelsSingle(tile);
    if (mapReadResult == null) return null;
    processMapReadResult(renderContext, tile, renderthemeLevel, mapReadResult);
    return renderContext;
  }

  /// Creates rendering instructions based on the given ways and nodes and the defined rendertheme
  void processMapReadResult(final RenderContext renderContext, Tile tile,
      RenderthemeLevel renderthemeLevel, DatastoreReadResult mapReadResult) {
    for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
      NodeProperties nodeProperties = NodeProperties(pointOfInterest);
      List<Shape> shapes =
          _retrieveShapesForPoi(tile, renderthemeLevel, nodeProperties);
      renderContext.setDrawingLayers(nodeProperties.layer);
      for (Shape shape in shapes) {
        shape.renderNode(renderContext, nodeProperties);
      }
    }

    // never ever call an async method 44000 times. It takes 2 seconds to do so!
//    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
    for (Way way in mapReadResult.ways) {
      WayProperties wayProperties = WayProperties(way);
      MapRectangle rectangle =
          wayProperties.getBoundary(renderContext.projection);
      // filter small ways
      if (rectangle.getWidth() < 5 && rectangle.getHeight() < 5) continue;
      if (wayProperties
          .getCoordinatesAbsolute(renderContext.projection)
          .isNotEmpty) {
        List<Shape> shapes;
        if (wayProperties.isClosedWay) {
          shapes = _retrieveShapesForClosedWay(
              tile, renderthemeLevel, wayProperties);
        } else {
          shapes =
              _retrieveShapesForOpenWay(tile, renderthemeLevel, wayProperties);
        }
        renderContext.setDrawingLayers(wayProperties.getLayer());
        for (Shape shape in shapes) {
          shape.renderWay(renderContext, wayProperties);
        }
      }
    }
    if (mapReadResult.isWater) {
      _renderWaterBackground(renderContext);
    }
    renderContext.reduce();
  }

  List<Shape> _retrieveShapesForPoi(Tile tile,
      RenderthemeLevel renderthemeLevel, NodeProperties nodeProperties) {
    List<Shape> shapes = renderthemeLevel.matchNode(tile, nodeProperties);
    return shapes;
  }

  List<Shape> _retrieveShapesForClosedWay(Tile tile,
      RenderthemeLevel renderthemeLevel, WayProperties wayProperties) {
    List<Shape> shapes =
        renderthemeLevel.matchClosedWay(tile, wayProperties.way);
    return shapes;
  }

  List<Shape> _retrieveShapesForOpenWay(Tile tile,
      RenderthemeLevel renderthemeLevel, WayProperties wayProperties) {
    List<Shape> shapes =
        renderthemeLevel.matchLinearWay(tile, wayProperties.way);
    return shapes;
  }

  void _renderWaterBackground(final RenderContext renderContext) {
    // renderContext.setDrawingLayers(0);
    // List<Mappoint> coordinates =
    //     getTilePixelCoordinates(renderContext.job.tileSize);
    // Mappoint tileOrigin =
    //     renderContext.projection.getLeftUpper(renderContext.job.tile);
    // for (int i = 0; i < coordinates.length; i++) {
    //   coordinates[i] = coordinates[i].offset(tileOrigin.x, tileOrigin.y);
    // }
    // Watercontainer way = Watercontainer(
    //     coordinates, renderContext.job.tile, [TAG_NATURAL_WATER]);
    //renderContext.renderTheme.matchClosedWay(databaseRenderer, renderContext, way);
  }
}
