import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/datastore_reader.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class IsolateDatastoreReader implements DatastoreReader {
  static DatastoreReaderImpl? _reader;

  /// a long-running instance of an isolate
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateDatastoreReader._(Datastore datastore);

  static Future<IsolateDatastoreReader> create(Datastore datastore) async {
    IsolateDatastoreReader instance = IsolateDatastoreReader._(datastore);
    await instance._isolateInstance.spawn(_createInstanceStatic, DatastoreReaderIsolateInitRequest(datastore));
    return instance;
  }

  @pragma('vm:entry-point')
  static Future<void> _createInstanceStatic(IsolateInitInstanceParams request) async {
    _reader = DatastoreReaderImpl((request.initObject as DatastoreReaderIsolateInitRequest).datastore);
    await FlutterIsolateInstance.isolateInit(request, _acceptRequestsStatic);
  }

  @pragma('vm:entry-point')
  static Future _acceptRequestsStatic(Object request) async {
    DatastoreReaderIsolateRequest r = request as DatastoreReaderIsolateRequest;
    if (r.rightLower == null) return _reader!.read(r.tile, r.renderthemeLevel);
    return _reader!.readLabels(r.tile, r.rightLower!, r.renderthemeLevel);
  }

  Future<LayerContainerCollection?> read(Tile tile, RenderthemeZoomlevel renderthemeLevel) async {
    return await _isolateInstance.compute(DatastoreReaderIsolateRequest(tile, renderthemeLevel));
  }

  Future<LayerContainerCollection?> readLabels(Tile leftUpper, Tile rightLower, RenderthemeZoomlevel renderthemeLevel) async {
    return await _isolateInstance.compute(DatastoreReaderIsolateRequest(leftUpper, renderthemeLevel, rightLower: rightLower));
  }
}

//////////////////////////////////////////////////////////////////////////////

class DatastoreReaderIsolateInitRequest {
  final Datastore datastore;

  DatastoreReaderIsolateInitRequest(this.datastore);
}
//////////////////////////////////////////////////////////////////////////////

class DatastoreReaderIsolateRequest {
  final Tile tile;
  final Tile? rightLower;
  final RenderthemeZoomlevel renderthemeLevel;

  DatastoreReaderIsolateRequest(this.tile, this.renderthemeLevel, {this.rightLower});
}

//////////////////////////////////////////////////////////////////////////////

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread. Returns the [LayerContainerCollection] whereas the clashingInfoCollection is already ordered and clash-free.
class DatastoreReaderImpl implements DatastoreReader {
  final Datastore datastore;

  DatastoreReaderImpl(this.datastore);

  @override
  Future<LayerContainerCollection?> read(Tile tile, RenderthemeZoomlevel renderthemeLevel) async {
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

  @override
  Future<LayerContainerCollection?> readLabels(Tile leftUpper, Tile rightLower, RenderthemeZoomlevel renderthemeLevel) async {
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
      if (renderinstructions.isEmpty) continue;
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
        if (renderinstructions.isEmpty) continue;
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
    List<Renderinstruction> shapes = renderthemeLevel.matchOpenWay(tile, wayProperties.way);
    return shapes;
  }
}
