import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/datastore_reader.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_canvas.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/util/datastore_reader_impl.dart';
import 'package:mapsforge_flutter_renderer/src/util/tile_dependencies.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

/// Testing if rendering in an isolate works. Unfortunately not since it is currently not allowed to call ui methods from another isolate.
@pragma("vm:entry-point")
class IsolateDatastoreRenderer implements Renderer {
  /// The instance of the mapfile in the isolate
  static DatastoreRenderer? renderer;

  /// a long-running instance of an isolate
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateDatastoreRenderer._();

  /// Creates a new `IsolateMapfile` instance.
  ///
  /// This will spawn a new isolate and initialize a `Mapfile` within it using
  /// the provided [filename] and [preferredLanguage].
  static Future<IsolateDatastoreRenderer> createRenderer({required Rendertheme rendertheme, required Datastore datastore}) async {
    IsolateDatastoreRenderer instance = IsolateDatastoreRenderer._();
    await instance._isolateInstance.spawn(_createInstanceStatic, _RendererInstanceRequest(rendertheme, datastore));
    return instance;
  }

  @override
  void dispose() {
    _isolateInstance.dispose();
  }

  @pragma('vm:entry-point')
  static Future<void> _createInstanceStatic(IsolateInitInstanceParams request) async {
    final rendertheme = (request.initObject as _RendererInstanceRequest).rendertheme;
    final datastore = request.initObject.datastore;
    renderer ??= DatastoreRenderer(datastore, rendertheme);
    await FlutterIsolateInstance.isolateInit(request, _acceptRequestsStatic);
  }

  @pragma('vm:entry-point')
  static Future _acceptRequestsStatic(Object request) async {
    if (request is _RendererExecuteRequest) return renderer!.executeJob(request.jobRequest);
    if (request is _RendererRetrieveLabelsRequest) return renderer!.retrieveLabels(request.jobRequest);
  }

  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    JobResult result = await _isolateInstance.compute(_RendererExecuteRequest(jobRequest));
    return result;
  }

  @override
  String getRenderKey() {
    return "1";
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest jobRequest) async {
    JobResult result = await _isolateInstance.compute(_RendererRetrieveLabelsRequest(jobRequest));
    return result;
  }

  @override
  bool supportLabels() {
    return true;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _RendererInstanceRequest {
  final Rendertheme rendertheme;

  final Datastore datastore;

  _RendererInstanceRequest(this.rendertheme, this.datastore);
}

//////////////////////////////////////////////////////////////////////////////

class _RendererExecuteRequest {
  final JobRequest jobRequest;

  _RendererExecuteRequest(this.jobRequest);
}

//////////////////////////////////////////////////////////////////////////////

class _RendererRetrieveLabelsRequest {
  final JobRequest jobRequest;

  _RendererRetrieveLabelsRequest(this.jobRequest);
}

//////////////////////////////////////////////////////////////////////////////

/// High-performance tile renderer for datastore-based map data.
///
/// This renderer converts map data from datastores into visual tile representations
/// by applying rendering themes and generating bitmap images. It supports both
/// static rendering (with labels) and dynamic rendering (without labels for rotation).
///
/// Key features:
/// - Efficient tile-based rendering with object pooling
/// - Theme-based styling with zoom level support
/// - Optional label rendering for rotation compatibility
/// - Spatial indexing for collision detection
/// - Performance optimizations with caching
class DatastoreRenderer extends Renderer {
  static final _log = Logger('DatastoreRenderer');

  /// Tag identifier for natural water features used in rendering optimization.
  static final Tag TAG_NATURAL_WATER = const Tag("natural", "water");

  /// Rendering theme defining visual styling rules.
  final Rendertheme rendertheme;

  /// Whether to render labels directly onto tile images.
  ///
  /// When true, labels are rendered onto tiles for better performance but
  /// prevent map rotation. When false, labels are rendered separately to
  /// support dynamic map rotation without label distortion.
  final bool useSeparateLabelLayer;

  final Datastore datastore;

  /// Manages dependencies between tiles for label rendering.
  TileDependencies? tileDependencies;

  /// Reader for extracting map data from the datastore.
  DatastoreReader? _datastoreReader;

  /// Object pool for RenderInfo sets to reduce garbage collection.
  static final ObjectPool<Set<RenderInfo>> _renderInfoSetPool = ObjectPool<Set<RenderInfo>>(
    factory: () => <RenderInfo>{},
    reset: (set) => set.clear(),
    maxSize: 20,
  );

  /// Creates a new datastore renderer with the specified configuration.
  ///
  /// [datastore] Data source providing map features
  /// [rendertheme] Theme defining visual styling rules
  /// [useSeparateLabelLayer] Whether to render labels at a separate layer (true) or onto the tiles directly (false
  /// [useIsolateReader] Whether to use an isolate for rendering. If you use [IsolateMapfile] do NOT use an isolateReader
  DatastoreRenderer(this.datastore, this.rendertheme, {this.useSeparateLabelLayer = true, bool useIsolateReader = false}) {
    if (useSeparateLabelLayer) {
      tileDependencies = null;
    } else {
      tileDependencies = TileDependencies();
    }
    if (!useIsolateReader) {
      _datastoreReader = DatastoreReaderImpl(datastore);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    tileDependencies?.dispose();
    rendertheme.dispose();
    datastore.dispose();
    super.dispose();
  }

  ///
  /// Executes a given job and returns a future with the bitmap of this job.
  /// @returns null if the datastore does not support the requested tile
  /// @returns the Bitmap for the requested tile
  @override
  Future<JobResult> executeJob(JobRequest job) async {
    var session = PerformanceProfiler().startSession(category: "DatastoreRenderer.executeJob");
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeZoomlevel renderthemeLevel = rendertheme.prepareZoomlevel(job.tile.zoomLevel);
    session.checkpoint("after prepareZoomlevel");

    _datastoreReader ??= await IsolateDatastoreReader.create(datastore);

    LayerContainerCollection? layerContainerCollection = await _datastoreReader!.read(job.tile, renderthemeLevel);

    //timing.lap(100, "RenderContext ${renderContext} created");
    if (layerContainerCollection == null) {
      return JobResult.unsupported();
    }

    UiCanvas canvas = UiCanvas.forRecorder(MapsforgeSettingsMgr().tileSize, MapsforgeSettingsMgr().tileSize);
    PixelProjection projection = PixelProjection(job.tile.zoomLevel);
    Mappoint leftUpper = projection.getLeftUpper(job.tile);
    UiRenderContext renderContext = UiRenderContext(canvas: canvas, reference: leftUpper, projection: projection);
    await PainterFactory().initDrawingLayers(layerContainerCollection.drawings);
    for (RenderInfo renderInfo in layerContainerCollection.drawings.renderInfos) {
      renderInfo.render(renderContext);
    }
    await PainterFactory().initDrawingLayers(layerContainerCollection.clashingInfoCollection);
    for (RenderInfo renderInfo in layerContainerCollection.clashingInfoCollection.renderInfos) {
      renderInfo.render(renderContext);
    }

    if (useSeparateLabelLayer) {
      // Returning the canvas with the map but without labels onto it. The labels have to be drawn directly into the view.
      layerContainerCollection.labels.clear();
    } else {
      // rendering the labels directly into the canvas. Rotation of labels if the map rotates is not supported in this case.
      layerContainerCollection.labels.collisionFreeOrdered();
      _processLabels(renderContext, layerContainerCollection.labels, job.tile);
      await PainterFactory().initDrawingLayers(layerContainerCollection.labels);
      for (RenderInfo renderInfo in layerContainerCollection.labels.renderInfos) {
        renderInfo.render(renderContext);
      }
    }
    session.checkpoint("data read and prepared");
    TilePicture? picture = await canvas.finalizeBitmap();
    canvas.dispose();
    session.complete();
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult.normal(picture, layerContainerCollection.labels);
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest job) async {
    var session = PerformanceProfiler().startSession(category: "DatastoreRenderer.retrieveLabels");
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeZoomlevel renderthemeLevel = rendertheme.prepareZoomlevel(job.tile.zoomLevel);

    _datastoreReader ??= await IsolateDatastoreReader.create(datastore);

    LayerContainerCollection? layerContainerCollection = await _datastoreReader!.readLabels(job.tile, job.rightLower ?? job.tile, renderthemeLevel);

    if (layerContainerCollection == null) {
      return JobResult.unsupported();
    }

    // it already collision-free
    //layerContainerCollection.labels.collisionFreeOrdered();
    await PainterFactory().initDrawingLayers(layerContainerCollection.labels);
    session.complete();
    return JobResult.normalLabels(layerContainerCollection.labels);
  }

  @override
  bool supportLabels() {
    return useSeparateLabelLayer;
  }

  void _processLabels(UiRenderContext renderContext, RenderInfoCollection renderInfoCollection, Tile tile) {
    // if we are drawing the labels per neighbour, we need to find out which neighbour-overlapping
    // elements need to be drawn.

    Set<Tile> neighbours = tileDependencies!.getNeighbours(tile);
    for (var renderInfo in renderInfoCollection.renderInfos) {
      for (Tile neighbour in neighbours) {
        if (renderInfo.intersects(renderContext.projection.boundaryAbsolute(neighbour))) {
          tileDependencies!.addOverlappingElement(renderInfo, neighbour);
        }
      }
    }

    // get the overlapping elements for the current tile which were found while rendering the neighbours
    Set<RenderInfo>? renderInfos = tileDependencies!.getOverlappingElements(tile);

    if (renderInfos != null) {
      for (var renderInfo in renderInfos) {
        renderInfoCollection.renderInfos.add(renderInfo);
      }
      tileDependencies!.setDrawn(tile);
    }
  }

  @override
  String getRenderKey() {
    return "${rendertheme.hashCode ^ useSeparateLabelLayer.hashCode}";
  }
}
