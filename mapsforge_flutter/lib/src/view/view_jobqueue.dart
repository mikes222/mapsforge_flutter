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

class ViewJobqueue with ChangeNotifier {
  static final _log = new Logger('ViewJobqueue');

  final ViewRenderer viewRenderer;

  final Storage<ViewJobRequest, RenderContext> storage =
      WeakReferenceStorage<ViewJobRequest, RenderContext>();

  late LruCache<ViewJobRequest, RenderContext> _cache;

  ViewJobRequest? _lastRequested;

  RenderContext? _renderContext;

  Subject<RenderContext> _injectRenderContext = BehaviorSubject();

  Stream<RenderContext> get observeRenderContext => _injectRenderContext.stream;

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

  RenderContext? getRenderContext() {
    return _renderContext;
  }

  Future<RenderContext?> getBoundaryTiles(
      ViewModel viewModel, MapViewPosition mapViewPosition) async {
    Timing timing = Timing(log: _log, active: true);
    List<Tile> tiles = _getTiles(viewModel, mapViewPosition);
    ViewJobRequest viewJobRequest = ViewJobRequest(
        upperLeft: tiles[0], lowerRight: tiles[1]);
    RenderContext? renderContext = _cache.get(viewJobRequest);
    timing.lap(50, "new request ${viewJobRequest.upperLeft}");
    if (renderContext != null) {
      _injectRenderContext.add(renderContext);
      _renderContext = renderContext;
      notifyListeners();
      return renderContext;
    }
    if (_lastRequested == viewJobRequest) return null;
    _lastRequested = viewJobRequest;
    timing.lap(50, "new request2 ${viewJobRequest.upperLeft}");
    ViewJobResult jobResult = await viewRenderer.executeViewJob(viewJobRequest);
    _cache[viewJobRequest] = jobResult.renderContext;
    _lastRequested = null;
    _renderContext = jobResult.renderContext;
    _injectRenderContext.add(jobResult.renderContext);
    notifyListeners();
    timing.lap(50, "new request3 ${viewJobRequest.upperLeft}");
    return jobResult.renderContext;
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  List<Tile> _getTiles(ViewModel viewModel, MapViewPosition mapViewPosition) {
    Mappoint center = mapViewPosition.getCenter();
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    double halfWidth = viewModel.mapDimension.width / 2;
    double halfHeight = viewModel.mapDimension.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = max(halfWidth, halfHeight);
    }
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    int tileLeft =
        mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(
        center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop =
        mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(
        center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      tileLeft = max(tileLeft - 1, 0);
      tileRight =
          min(tileRight + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - 1, 0);
      tileBottom =
          min(tileBottom + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    Tile upperLeft = Tile(tileLeft, tileTop, zoomLevel, indoorLevel);
    Tile lowerRight = Tile(tileRight, tileBottom, zoomLevel, indoorLevel);
    return [upperLeft, lowerRight];
  }
}
