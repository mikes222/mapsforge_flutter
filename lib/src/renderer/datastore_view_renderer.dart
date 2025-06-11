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

  DatastoreViewRenderer({required this.datastore, required this.renderTheme, required this.symbolCache}) {
    _datastoreReader = DatastoreReader();
  }

  @override
  Future<ViewJobResult> executeViewJob(ViewJobRequest viewJobRequest) async {
    Timing timing = Timing(log: _log, active: true, prefix: "${viewJobRequest.upperLeft}-${viewJobRequest.lowerRight} ");
    RenderContext renderContext = RenderContext(viewJobRequest.upperLeft, renderTheme.levels);
    RenderthemeLevel renderthemeLevel = this.renderTheme.prepareZoomlevel(viewJobRequest.upperLeft.zoomLevel);

    DatastoreReadResult mapReadResult = await datastore.readMapData(viewJobRequest.upperLeft, viewJobRequest.lowerRight);

    if ((mapReadResult.ways.length) > 100000) {
      _log.warning("Many ways (${mapReadResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }
    timing.lap(50, "${mapReadResult.ways.length} ways and ${mapReadResult.pointOfInterests.length} pois initialized");
    // print(
    //     "pois: ${readResult.pointOfInterests.length}, way: ${readResult.ways.length} for ${viewJobRequest.upperLeft}");
    _datastoreReader.processMapReadResult(renderContext, viewJobRequest.upperLeft, renderthemeLevel, mapReadResult);
    renderContext.reduce();

    await renderContext.initDrawingLayers(symbolCache);

    List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(renderContext.labels, renderContext.projection);
    renderContext.labels.clear();
    renderContext.labels.addAll(renderInfos);
    for (List<RenderInfo> wayList in renderContext.clashDrawingLayer.ways) {
      List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(wayList, renderContext.projection);
      wayList.clear();
      wayList.addAll(renderInfos);
    }

    timing.done(50, "${mapReadResult.ways.length} ways, ${mapReadResult.pointOfInterests.length} pois, ${renderContext}");
    //renderContext.statistics();
    return ViewJobResult(renderContext: renderContext);
  }

  @override
  String getRenderKey() {
    return "${renderTheme.hashCode}";
  }
}
