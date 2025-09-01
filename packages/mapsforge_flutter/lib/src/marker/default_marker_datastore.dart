import 'dart:async';

import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/map_model.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

class DefaultMarkerDatastore<T> extends MarkerDatastore<T> {
  /// All known markers
  final Map<T, Marker<T>> _markers = {};

  final Set<Marker<T>> _reinitRequestedMarkers = {};

  /// The markers which are currently eligible to paint on screen
  final Set<Marker<T>> _cachedMarkers = {};

  bool _disposed = false;

  final MapModel mapModel;

  int _zoomlevel = -1;

  BoundingBox? _boundingBox;

  DefaultMarkerDatastore({required this.mapModel}) {
    mapModel.registerMarkerDatastore(this);
  }

  @override
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    _cachedMarkers.clear();
    _reinitRequestedMarkers.clear();
    _zoomlevel = zoomlevel;
    _boundingBox = boundingBox;
    reinitMarkers(zoomlevel, boundingBox, projection);
  }

  void reinitMarkers(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    for (var marker in _markers.values) {
      if (marker.shouldPaint(boundingBox, zoomlevel)) {
        _reinitRequestedMarkers.add(marker);
      }
    }
    unawaited(_performReinit(zoomlevel, projection));
  }

  @override
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox) {
    _cachedMarkers.clear();
    for (var marker in _markers.values) {
      if (marker.shouldPaint(boundingBox, zoomlevel)) {
        _cachedMarkers.add(marker);
      }
    }
    _zoomlevel = zoomlevel;
    _boundingBox = boundingBox;
  }

  @override
  Iterable<Marker<T>> askRetrieveMarkersToPaint() {
    return _cachedMarkers;
  }

  Future<void> _performReinit(int zoomlevel, PixelProjection projection) async {
    try {
      for (var marker in _reinitRequestedMarkers) {
        await marker.changeZoomlevel(zoomlevel, projection);
        _cachedMarkers.add(marker);
      }
    } on ConcurrentModificationError catch (_) {
      // seems in the meantime we should change additional items, stop here and let the next call do the job
      return;
    }
    _reinitRequestedMarkers.clear();
  }

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  @override
  void addMarker(Marker<T> marker) {
    assert(marker.key != null, "Marker must have a key for default MarkerDatastore");
    _markers[marker.key!] = marker;
    if (_zoomlevel != -1 && marker.shouldPaint(_boundingBox!, _zoomlevel)) {
      _reinitRequestedMarkers.add(marker);
    }
  }

  @override
  void markerChanged(Marker<T> marker) {
    assert(marker.key != null, "Marker must have a key for default MarkerDatastore");
    _markers[marker.key!] = marker;
  }

  /// Do not forget to call setRepaint()
  @override
  void removeMarker(Marker<T> marker) {
    _markers.remove(marker.key);
    marker.dispose();
    _cachedMarkers.remove(marker.key);
  }

  void removeByKey(T key) {
    Marker<T>? marker = _markers.remove(key);
    marker?.dispose();
    _cachedMarkers.remove(key);
  }

  /// Do not forget to call setRepaint()
  @override
  void clearMarkers() {
    for (var marker in _markers.values) {
      marker.dispose();
    }
    _markers.clear();
    _cachedMarkers.clear();
  }

  Marker<T>? getMarker(T key) {
    return _markers[key];
  }

  List<Marker<T>> getAllMarkers() {
    return _markers.values.toList();
  }

  @override
  List<Marker<T>> getTappedMarkers(TapEvent event) {
    List<Marker<T>> tappedMarkers = [];
    for (var marker in _cachedMarkers) {
      if (marker.isTapped(event)) tappedMarkers.add(marker);
    }
    return tappedMarkers;
  }

  /// In future versions we want to notify the ui about a necessary repaint because something has been changed
  void setRepaint() {
    if (_zoomlevel != -1) unawaited(_performReinit(_zoomlevel, PixelProjection(_zoomlevel)));
  }

  @override
  void dispose() {
    mapModel.unregisterMarkerDatastore(this);
    _cachedMarkers.clear();
    _reinitRequestedMarkers.clear();
    _markers.forEach((key, value) {
      value.dispose();
    });
    _markers.clear();
    _disposed = true;
  }

  bool get disposed => _disposed;
}
