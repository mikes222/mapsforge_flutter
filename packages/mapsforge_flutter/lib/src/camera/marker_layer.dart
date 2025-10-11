import 'dart:async';
import 'dart:ui';

import 'package:mapsforge_flutter/src/camera/map_camera.dart';
import 'package:mapsforge_flutter/src/camera/map_layer.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore_painter.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

class MarkerLayer<T> extends MapLayer {
  final MarkerDatastore<T> datastore;
  final ZoomlevelRange zoomRange;
  double extendMargin;
  int _cachedZoom = -1;
  BoundingBox? _cachedBounds;
  Timer? _debounce;

  // Track last center (in pixel space) and zoom we loaded for
  Mappoint? _lastCenterPx;

  static const _debounceMs = 24; // ~1.5 frames @60fps
  static const _moveThresholdPx = 32.0; // require ~32px movement before refetch

  MarkerLayer({
    required this.datastore,
    required this.zoomRange,
    this.extendMargin = 1.5,
  });

  @override
  int get zIndex => 10; // paint above tiles

  @override
  void attach({required MapCamera camera}) {
    super.attach(camera: camera);
    datastore.addListener(notifyListeners);
    camera.addListener(_onCameraChanged);
    _onCameraChanged(); // initial run; will no-op if still not fully ready
  }

  void _refreshForCamera() {
    if (!isAttached) return;

    final position = camera.position;
    final view = camera.viewport;
    if (view.isEmpty) return;

    final scale = MapsforgeSettingsMgr().getDeviceScaleFactor();

    // Compute current center in pixel space (zoom-aware)
    final centerPx = position.getCenter(); // Mappoint in absolute pixels

    // If zoom is unchanged, check if we actually moved enough (ignore pure rotation/scaleAround jitter)
    if (_cachedZoom == position.zoomlevel && _lastCenterPx != null) {
      final dx = (centerPx.x - _lastCenterPx!.x).abs();
      final dy = (centerPx.y - _lastCenterPx!.y).abs();
      if (dx < _moveThresholdPx * scale && dy < _moveThresholdPx * scale) {
        // Movement too small → no bbox update
        return;
      }
    }

    // Calculate axis-aligned bbox of the screen (rotation can change it slightly)
    var bbox = TileHelper.calculateBoundingBoxOfScreen(
      mapPosition: position,
      screensize: view * scale,
    );

    if (_cachedZoom != position.zoomlevel) {
      if (zoomRange.isWithin(position.zoomlevel)) {
        final ext = bbox.extendMargin(extendMargin);
        datastore.askChangeZoomlevel(
          position.zoomlevel,
          ext,
          position.projection,
        );
        _cachedZoom = position.zoomlevel;
        _cachedBounds = ext;
      } else {
        _cachedZoom = position.zoomlevel;
        _cachedBounds = null;
      }
    } else {
      // Same zoom: update only if we left the cached extended bbox
      if (_cachedBounds == null || !_cachedBounds!.containsBoundingBox(bbox)) {
        final ext = bbox.extendMargin(extendMargin);
        datastore.askChangeBoundingBox(_cachedZoom, ext);
        _cachedBounds = ext;
      }
    }

    _lastCenterPx = centerPx;
  }

  void _onCameraChanged() {
    if (!isAttached) return; // <-- guard
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: _debounceMs),
      _refreshForCamera,
    );
    final position = camera.position;
    final view = camera.viewport;
    if (view.isEmpty) return;

    final scale = MapsforgeSettingsMgr().getDeviceScaleFactor();
    var bbox = TileHelper.calculateBoundingBoxOfScreen(
      mapPosition: position,
      screensize: view * scale,
    );

    if (_cachedZoom != position.zoomlevel) {
      if (zoomRange.isWithin(position.zoomlevel)) {
        final ext = bbox.extendMargin(extendMargin);
        datastore.askChangeZoomlevel(
          position.zoomlevel,
          ext,
          position.projection,
        );
        _cachedZoom = position.zoomlevel;
        _cachedBounds = ext;
      }
      return;
    }

    if (_cachedBounds == null || !_cachedBounds!.containsBoundingBox(bbox)) {
      final ext = bbox.extendMargin(extendMargin);
      datastore.askChangeBoundingBox(_cachedZoom, ext);
      _cachedBounds = ext;
    }
  }

  @override
  void dispose() {
    if (isAttached) camera.removeListener(_onCameraChanged);
    datastore.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!isAttached) return; // <-- guard
    MarkerDatastorePainter(camera.position, datastore).paint(canvas, size);
  }
}
