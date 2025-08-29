import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';

class DatastoreReaderIsolate {
  static DatastoreReader? _reader;

  @pragma('vm:entry-point')
  static Future<LayerContainerCollection?> read(DatastoreReaderIsolateRequest request) async {
    _reader ??= DatastoreReader();
    return _reader!.read(request.datastore, request.tile, request.renderthemeLevel);
  }

  @pragma('vm:entry-point')
  static Future<LayerContainerCollection?> readLabels(DatastoreReaderIsolateRequest request) async {
    _reader ??= DatastoreReader();
    return _reader!.readLabels(request.datastore, request.tile, request.tile, request.renderthemeLevel);
  }
}

//////////////////////////////////////////////////////////////////////////////

class DatastoreReaderIsolateRequest {
  final Datastore datastore;
  final Tile tile;
  final Tile? lowerRight;
  final RenderthemeZoomlevel renderthemeLevel;
  final int maxLevels;

  DatastoreReaderIsolateRequest(this.datastore, this.tile, this.renderthemeLevel, this.maxLevels, {this.lowerRight});
}

//////////////////////////////////////////////////////////////////////////////

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread.
class DatastoreReader {
  DatastoreReader();

  Future<LayerContainerCollection?> read(Datastore datastore, Tile tile, RenderthemeZoomlevel renderthemeLevel) async {
    if (!(await datastore.supportsTile(tile))) {
      return null;
    }
    DatastoreBundle? datastoreBundle = await datastore.readMapDataSingle(tile);
    if (datastoreBundle == null) {
      return null;
    }
    LayerContainerCollection layerContainerCollection = LayerContainerCollection(renderthemeLevel.maxLevels);
    _processMapReadResult(layerContainerCollection, tile, renderthemeLevel, datastoreBundle);
    layerContainerCollection.clashingInfoCollection.collisionFreeOrdered();
    return layerContainerCollection;
  }

  Future<LayerContainerCollection?> readLabels(Datastore datastore, Tile leftUpper, Tile rightLower, RenderthemeZoomlevel renderthemeLevel) async {
    // if (!(await datastore.supportsTile(leftUpper))) {
    //   return null;
    // }
    DatastoreBundle? datastoreBundle = await datastore.readLabels(leftUpper, rightLower);
    if (datastoreBundle == null) return null;
    LayerContainerCollection layerContainerCollection = LayerContainerCollection(renderthemeLevel.maxLevels);
    _processMapReadResult(layerContainerCollection, leftUpper, renderthemeLevel, datastoreBundle);
    layerContainerCollection.drawings.clear();
    layerContainerCollection.clashingInfoCollection.clear();
    layerContainerCollection.labels.collisionFreeOrdered();
    return layerContainerCollection;
  }

  /// Creates rendering instructions based on the given ways and nodes and the defined rendertheme
  void _processMapReadResult(
    LayerContainerCollection layerContainerCollection,
    Tile tile,
    RenderthemeZoomlevel renderthemeLevel,
    DatastoreBundle datastoreBundle,
  ) {
    PixelProjection projection = PixelProjection(tile.zoomLevel);
    for (PointOfInterest pointOfInterest in datastoreBundle.pointOfInterests) {
      List<Renderinstruction> renderinstructions = renderthemeLevel.matchNode(tile.indoorLevel, pointOfInterest);
      LayerContainer layerContainer = layerContainerCollection.getLayer(pointOfInterest.layer);
      NodeProperties nodeProperties = NodeProperties(pointOfInterest, projection);
      for (Renderinstruction renderinstruction in renderinstructions) {
        renderinstruction.matchNode(layerContainer, nodeProperties);
      }
    }

    // never ever call an async method 44000 times. It takes 2 seconds to do so!
    //    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
    for (Way way in datastoreBundle.ways) {
      WayProperties wayProperties = WayProperties(way, projection);
      MapRectangle rectangle = wayProperties.getBoundaryAbsolute();
      // filter small ways
      if (rectangle.getWidth() < 5 && rectangle.getHeight() < 5) continue;
      if (wayProperties.getCoordinatesAbsolute().isNotEmpty) {
        List<Renderinstruction> renderinstructions;
        if (wayProperties.isClosedWay) {
          renderinstructions = _retrieveShapesForClosedWay(tile, renderthemeLevel, wayProperties);
        } else {
          renderinstructions = _retrieveShapesForOpenWay(tile, renderthemeLevel, wayProperties);
        }
        LayerContainer layerContainer = layerContainerCollection.getLayer(way.layer);
        for (Renderinstruction renderinstruction in renderinstructions) {
          renderinstruction.matchWay(layerContainer, wayProperties);
        }
      }
    }
    // if (mapReadResult.isWater) {
    //   _renderWaterBackground(renderContext);
    // }
    layerContainerCollection.reduce();
  }

  List<Renderinstruction> _retrieveShapesForClosedWay(Tile tile, RenderthemeZoomlevel renderthemeLevel, WayProperties wayProperties) {
    List<Renderinstruction> shapes = renderthemeLevel.matchClosedWay(tile, wayProperties.way);
    return shapes;
  }

  List<Renderinstruction> _retrieveShapesForOpenWay(Tile tile, RenderthemeZoomlevel renderthemeLevel, WayProperties wayProperties) {
    List<Renderinstruction> shapes = renderthemeLevel.matchLinearWay(tile, wayProperties.way);
    return shapes;
  }
}
