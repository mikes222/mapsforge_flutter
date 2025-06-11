import 'dart:math';

import 'package:ecache/ecache.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_request.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_result.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercontext.dart';
import 'package:rxdart/rxdart.dart';

import '../../core.dart';
import '../renderer/view_renderer.dart';
import '../utils/timing.dart';

class ViewJobqueue extends ChangeNotifier {
  static final _log = new Logger('ViewJobqueue');

  final ViewRenderer viewRenderer;

  final Storage<ViewJobRequest, RenderContext> storage = WeakReferenceStorage<ViewJobRequest, RenderContext>();

  late LruCache<ViewJobRequest, RenderContext> _cache;

  ViewJobRequest? _lastRequested;

  Subject<RenderContext> _injectRenderContext = BehaviorSubject();

  Stream<RenderContext> get observeRenderContext => _injectRenderContext.stream;

  RenderContext? renderContext;

  ViewJobqueue({required this.viewRenderer}) {
    _cache = new LruCache<ViewJobRequest, RenderContext>(
      storage: storage,
      capacity: 100,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _injectRenderContext.close();
  }

  Future<RenderContext?> getBoundaryTiles(ViewModel viewModel, MapViewPosition mapViewPosition, Size screensize) async {
    Timing timing = Timing(log: _log, active: true);
    List<Tile> tiles = _getTiles(viewModel, mapViewPosition, screensize);
    ViewJobRequest viewJobRequest = ViewJobRequest(upperLeft: tiles[0], lowerRight: tiles[1]);
    RenderContext? renderContext = _cache.get(viewJobRequest);
    timing.lap(10, "new request ${viewJobRequest.upperLeft}-${viewJobRequest.lowerRight}");
    if (renderContext != null) {
      if (renderContext == this.renderContext) return renderContext;
      _injectRenderContext.add(renderContext);
      this.renderContext = renderContext;
      notifyListeners();
      timing.lap(0, "after execute existing request ${viewJobRequest.upperLeft}-${viewJobRequest.lowerRight}");
      return renderContext;
    }
    if (_lastRequested == viewJobRequest) return null;
    _lastRequested = viewJobRequest;
    timing.lap(10, "Before execute new request ${viewJobRequest.upperLeft}-${viewJobRequest.lowerRight}");
    ViewJobResult jobResult = await viewRenderer.executeViewJob(viewJobRequest);
    _cache[viewJobRequest] = jobResult.renderContext;
    _lastRequested = null;
    _injectRenderContext.add(jobResult.renderContext);
    this.renderContext = jobResult.renderContext;
    notifyListeners();
    timing.done(0, "after execute new request ${viewJobRequest.upperLeft}-${viewJobRequest.lowerRight}");
    return jobResult.renderContext;
  }

  ///
  /// Gets upper-left and lower-right tile for the given view
  ///
  List<Tile> _getTiles(ViewModel viewModel, MapViewPosition mapViewPosition, Size screensize) {
    Mappoint center = mapViewPosition.getCenter();
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    double halfWidth = screensize.width / 2;
    double halfHeight = screensize.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = max(halfWidth, halfHeight);
    }
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    int tileLeft = mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop = mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      tileLeft = max(tileLeft - 1, 0);
      tileRight = min(tileRight + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - 1, 0);
      tileBottom = min(tileBottom + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    Tile upperLeft = Tile(tileLeft, tileTop, zoomLevel, indoorLevel);
    Tile lowerRight = Tile(tileRight, tileBottom, zoomLevel, indoorLevel);
    return [upperLeft, lowerRight];
  }
}
