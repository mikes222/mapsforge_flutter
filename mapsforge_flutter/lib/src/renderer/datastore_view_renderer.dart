import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_request.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_result.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/renderinfo.dart';
import '../utils/layerutil.dart';
import '../utils/timing.dart';
import 'datastorereader.dart';

class DatastoreViewRenderer extends ViewRenderer {
  static final _log = new Logger('DatastoreViewRenderer');

  final Datastore datastore;

  final RenderTheme renderTheme;

  final SymbolCache symbolCache;

  late DatastoreReader _datastoreReader;

  DatastoreViewRenderer(
      {required this.datastore,
      required this.renderTheme,
      required this.symbolCache}) {
    _datastoreReader = DatastoreReader();
  }

  @override
  Future<ViewJobResult> executeViewJob(ViewJobRequest viewJobRequest) async {
    Timing timing = Timing(log: _log, active: true);
    RenderContext renderContext = RenderContext(
        viewJobRequest.upperLeft, viewJobRequest.tileSize, renderTheme.levels);
    this.renderTheme.prepareScale(viewJobRequest.upperLeft.zoomLevel);
    await datastore.lateOpen();
    // if (!datastore.supportsTile(upperLeft, projection) &&
    //     !datastore.supportsTile(lowerRight, projection)) {
    //   return DatastoreReadResult(pointOfInterests: [], ways: []);
    // }
    DatastoreReadResult readResult = await datastore.readMapData(
        viewJobRequest.upperLeft, viewJobRequest.lowerRight);

    if ((readResult.ways.length) > 100000) {
      _log.warning(
          "Many ways (${readResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }
    timing.lap(50,
        "${readResult.ways.length} ways and ${readResult.pointOfInterests.length} pois initialized for tile ${renderContext.upperLeft}");
    // print(
    //     "pois: ${readResult.pointOfInterests.length}, way: ${readResult.ways.length} for ${viewJobRequest.upperLeft}");
    _datastoreReader.processMapReadResult(
        renderContext, renderTheme, readResult);
    renderContext.reduce();
    // renderContext.drawingLayers.forEach((LayerPaintContainer layer) {
    //   layer.ways.forEach((List<RenderInfo<Shape>> ways) {
    //     ways.forEach((RenderInfo<Shape> renderInfo) {
    //       MapRectangle rectangle =
    //           renderInfo.getBoundaryAbsolute(renderContext.projection);
    //       if (rectangle.getWidth() < 5 && rectangle.getHeight() < 5)
    //         print(
    //             "Way $renderInfo ${rectangle.getWidth()} * ${rectangle.getHeight()}");
    //     });
    //   });
    // });

    await renderContext.initDrawingLayers(symbolCache);

    List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(
        renderContext.labels, renderContext.projection);
    renderContext.labels.clear();
    renderContext.labels.addAll(renderInfos);
    for (List<RenderInfo> wayList in renderContext.clashDrawingLayer.ways) {
      List<RenderInfo> renderInfos =
          LayerUtil.collisionFreeOrdered(wayList, renderContext.projection);
      wayList.clear();
      wayList.addAll(renderInfos);
    }

    timing.lap(50, "storeMapItems for tile ${renderContext.upperLeft}");
    //renderContext.statistics();
    return ViewJobResult(renderContext: renderContext);
  }

  @override
  String getRenderKey() {
    return "${renderTheme.hashCode}";
  }
}
