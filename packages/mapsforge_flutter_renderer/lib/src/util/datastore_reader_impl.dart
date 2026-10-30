import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/src/datastore_reader.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

/// An implementation of `DatastoreReader` that performs the reading and processing
/// of map data in a separate isolate.
///
/// This is crucial for performance, as it prevents the UI thread from being
/// blocked by the CPU-intensive work of reading map files and matching them
/// against a render theme.
class IsolateDatastoreReader implements DatastoreReader {
  static DatastoreReaderImpl? _reader;

  /// a long-running instance of an isolate
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateDatastoreReader._(Datastore datastore);

  /// Creates and spawns a new `IsolateDatastoreReader`.
  static Future<IsolateDatastoreReader> create(Datastore datastore, {bool highDetailWays = false}) async {
    IsolateDatastoreReader instance = IsolateDatastoreReader._(datastore);
    await instance._isolateInstance.spawn(_createInstanceStatic, DatastoreReaderIsolateInitRequest(datastore, highDetailWays: highDetailWays));
    return instance;
  }

  @pragma('vm:entry-point')
  static Future<void> _createInstanceStatic(IsolateInitInstanceParams request) async {
    DatastoreReaderIsolateInitRequest initRequest = request.initObject as DatastoreReaderIsolateInitRequest;
    _reader = DatastoreReaderImpl(initRequest.datastore, highDetailWays: initRequest.highDetailWays);
    await FlutterIsolateInstance.isolateInit(request, _acceptRequestsStatic);
  }

  @pragma('vm:entry-point')
  static Future _acceptRequestsStatic(Object request) async {
    DatastoreReaderIsolateRequest r = request as DatastoreReaderIsolateRequest;
    if (r.rightLower == null) return _reader!.read(r.tile, r.renderthemeLevel);
    return _reader!.readLabels(r.tile, r.rightLower!, r.renderthemeLevel);
  }

  @override
  Future<LayerContainerCollection?> read(Tile tile, RenderthemeZoomlevel renderthemeLevel) async {
    return _isolateInstance.compute(DatastoreReaderIsolateRequest(tile, renderthemeLevel));
  }

  @override
  Future<LayerContainerCollection?> readLabels(Tile leftUpper, Tile rightLower, RenderthemeZoomlevel renderthemeLevel) async {
    return _isolateInstance.compute(DatastoreReaderIsolateRequest(leftUpper, renderthemeLevel, rightLower: rightLower));
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A message to initialize the `DatastoreReaderImpl` in the isolate.
class DatastoreReaderIsolateInitRequest {
  final Datastore datastore;

  final bool highDetailWays;

  DatastoreReaderIsolateInitRequest(this.datastore, {this.highDetailWays = false});
}
//////////////////////////////////////////////////////////////////////////////

/// A message to request the reading of map data in the isolate.
class DatastoreReaderIsolateRequest {
  final Tile tile;
  final Tile? rightLower;
  final RenderthemeZoomlevel renderthemeLevel;

  DatastoreReaderIsolateRequest(this.tile, this.renderthemeLevel, {this.rightLower});
}

//////////////////////////////////////////////////////////////////////////////

/// An implementation of `DatastoreReader` that performs the reading and processing
/// of map data in the same thread.
///
/// This class reads data from a `Datastore` (e.g., a .map file), matches it
/// against a `RenderTheme`, and produces a `LayerContainerCollection` that can
/// be rendered.
class DatastoreReaderImpl implements DatastoreReader {
  final Datastore datastore;

  /// If true, tiny road, rail and border open ways are kept and simplified with a 1 px
  /// instead of a 5 px tolerance. Avoids gaps in roads made of many short ways.
  final bool highDetailWays;

  DatastoreReaderImpl(this.datastore, {this.highDetailWays = false});

  /// Reads the map data for a single [tile] and processes it against the
  /// [renderthemeLevel].
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

  /// Reads the label data for a given tile range and processes it against the
  /// [renderthemeLevel].
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
      final bool isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]);
      // Cheap rejection before any projection: open ways without a matching rendering rule are never drawn.
      if (!isClosedWay && renderthemeLevel.matchOpenWay(tile, way).isEmpty) continue;

      // Cheap pre-filter using the projected bounding box of the way.
      // This avoids the expensive full projection and Douglas-Peucker simplification
      // for ways that are too small to be rendered.
      MapRectangle bbox = projection.boundingBoxToRectangle(way.getBoundingBox());
      bool tooSmall = bbox.getWidth() < 5 && bbox.getHeight() < 5;
      // In high detail mode, tiny open roads and borders are kept so that roads made of many short pieces have no gaps.
      bool keepSmallOpenWay = highDetailWays && !isClosedWay && _isKeepableSmallOpenWay(way);
      if (tooSmall && !keepSmallOpenWay) continue;

      WayProperties wayProperties = WayProperties(
        way,
        projection,
        simplificationTolerance: keepSmallOpenWay ? 1 : 5,
        keepSmallOpenWays: keepSmallOpenWay,
      );
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

  /// Tiny open ways that are kept in high detail mode: road and rail pieces and country/state borders.
  static bool _isKeepableSmallOpenWay(Way way) {
    TagCollection tags = way.tags;
    if (tags.hasTag('highway') || tags.hasTag('railway')) return true;
    if (tags.hasTagValue('boundary', 'administrative')) {
      String? adminLevel = tags.getTag('admin_level');
      return adminLevel == '2' || adminLevel == '4';
    }
    return false;
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
