import 'dart:async';

import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/map_model.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

class DefaultMarkerDatastore<T> extends MarkerDatastore<T> {
  /// All known markers
  final Map<T, Marker<T>> _markers = {};

  /// All initialized markers which can be painted at the current zoomlevel but which may be outside of the current bounding box
  final Set<Marker<T>> _initializedMarkers = {};

  /// The markers which are currently eligible to paint on screen
  final Set<Marker<T>> _cachedMarkers = {};

  bool _disposed = false;

  final MapModel mapModel;

  int _zoomlevel = -1;

  BoundingBox? _boundingBox;

  int _iteration = 0;

  DefaultMarkerDatastore({required this.mapModel}) {
    mapModel.registerMarkerDatastore(this);
  }

  @override
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    ++_iteration;
    _initializedMarkers.clear();
    _cachedMarkers.clear();
    _zoomlevel = zoomlevel;
    _boundingBox = boundingBox;
    unawaited(reinitMarkers(_iteration, zoomlevel, boundingBox, projection));
  }

  /// reinit all markers after zoomlevel changed
  Future<void> reinitMarkers(int iteration, int zoomlevel, BoundingBox boundingBox, PixelProjection projection) async {
    int count = 0;
    for (var marker in List.of(_markers.values)) {
      if (marker.shouldPaint(boundingBox, zoomlevel)) {
        await reinitOneMarker(marker, zoomlevel, boundingBox, projection);
        // zoomlevel changed again, stop here
        if (iteration != _iteration) break;
        ++count;
        if ((count % 100) == 0) {
          // every 100 markers trigger a repaint
          setRepaint();
        }
      }
    }
    setRepaint();
  }

  Future<void> reinitOneMarker(Marker<T> marker, int zoomlevel, BoundingBox boundingBox, PixelProjection projection) async {
    await marker.changeZoomlevel(zoomlevel, projection);
    _initializedMarkers.add(marker);
    _cachedMarkers.add(marker);
  }

  @override
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox) {
    _cachedMarkers.clear();
    for (var marker in _initializedMarkers) {
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

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  @override
  void addMarker(Marker<T> marker) {
    assert(marker.key != null, "Marker must have a key for default MarkerDatastore");
    _markers[marker.key!] = marker;
    if (_zoomlevel != -1 && marker.shouldPaint(_boundingBox!, _zoomlevel)) {
      reinitOneMarker(marker, _zoomlevel, _boundingBox!, PixelProjection(_zoomlevel)).then((value) {
        setRepaint();
      });
    }
  }

  @override
  void markerChanged(Marker<T> marker) {
    assert(marker.key != null, "Marker must have a key for default MarkerDatastore");
    _markers[marker.key!] = marker;
    if (_zoomlevel != -1 && marker.shouldPaint(_boundingBox!, _zoomlevel)) {
      reinitOneMarker(marker, _zoomlevel, _boundingBox!, PixelProjection(_zoomlevel)).then((value) {
        setRepaint();
      });
    }
  }

  /// Do not forget to call setRepaint()
  @override
  void removeMarker(Marker<T> marker) {
    _markers.remove(marker.key);
    _initializedMarkers.remove(marker);
    _cachedMarkers.remove(marker);
    marker.dispose();
  }

  void removeByKey(T key) {
    Marker<T>? marker = _markers.remove(key);
    if (marker != null) {
      _initializedMarkers.remove(marker);
      _cachedMarkers.remove(marker);
      marker.dispose();
    }
  }

  /// Do not forget to call setRepaint()
  @override
  void clearMarkers() {
    for (var marker in _markers.values) {
      marker.dispose();
    }
    _markers.clear();
    _initializedMarkers.clear();
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

  @override
  void dispose() {
    super.dispose();
    mapModel.unregisterMarkerDatastore(this);
    _initializedMarkers.clear();
    _cachedMarkers.clear();
    _markers.forEach((key, value) {
      value.dispose();
    });
    _markers.clear();
    _disposed = true;
  }

  bool get disposed => _disposed;
}
