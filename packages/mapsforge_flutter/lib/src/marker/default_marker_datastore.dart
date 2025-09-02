import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/map_model.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

class DefaultMarkerDatastore<T> extends MarkerDatastore<T> {
  /// All known markers
  final Set<Marker<T>> _markers = {};

  _CurrentMarkers<T>? _currentMarkers;

  bool _disposed = false;

  final MapModel mapModel;

  DefaultMarkerDatastore({required this.mapModel}) {
    mapModel.registerMarkerDatastore(this);
  }

  @override
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    _currentMarkers?.stop = true;
    _CurrentMarkers<T> currentMarkers = _CurrentMarkers(zoomlevel: zoomlevel, boundingBox: boundingBox, projection: projection);
    _currentMarkers = currentMarkers;
    unawaited(_reinitMarkers(currentMarkers, List.of(_markers)));
  }

  /// reinit all markers after zoomlevel changed
  Future<void> _reinitMarkers(_CurrentMarkers<T> currentMarkers, List<Marker<T>> markers) async {
    int count = 0;
    for (var marker in markers) {
      if (marker.shouldPaint(currentMarkers.boundingBox, currentMarkers.zoomlevel)) {
        await reinitOneMarker(currentMarkers, marker);
        if (currentMarkers.stop) return;
        ++count;
        if ((count % 100) == 0) {
          // every 100 markers trigger a repaint
          // setRepaint would not work without setting the currentMarkers to the class variable
          requestRepaint();
        }
      }
    }
    if ((count % 100) != 0 && !currentMarkers.stop) {
      // everything reinitialized, repaint now
      requestRepaint();
    }
    // print(
    //   "DefaultMarkerDatastore._reinitMarkers for zoomlevel ${currentMarkers.zoomlevel}, length: ${markers.length} ${currentMarkers._cachedMarkers.length} $this",
    // );
  }

  Future<void> reinitOneMarker(_CurrentMarkers<T> currentMarkers, Marker<T> marker) async {
    await marker.changeZoomlevel(currentMarkers.zoomlevel, currentMarkers.projection);
    currentMarkers._initializedMarkers.add(marker);
    currentMarkers._cachedMarkers.add(marker);
  }

  @override
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox) {
    _currentMarkers?.stop = true;
    _CurrentMarkers<T> currentMarkers = _CurrentMarkers(zoomlevel: zoomlevel, boundingBox: boundingBox, projection: PixelProjection(zoomlevel));
    currentMarkers._initializedMarkers.addAll(_currentMarkers?._initializedMarkers ?? []);
    _currentMarkers = currentMarkers;
    for (var marker in currentMarkers._initializedMarkers) {
      if (marker.shouldPaint(boundingBox, zoomlevel)) {
        currentMarkers._cachedMarkers.add(marker);
      }
    }
  }

  @override
  Iterable<Marker<T>> askRetrieveMarkersToPaint() {
    return _currentMarkers?._cachedMarkers ?? [];
  }

  /// Adds a new marker.
  @override
  void addMarker(Marker<T> marker) {
    _markers.add(marker);
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    if (currentMarkers != null && marker.shouldPaint(currentMarkers.boundingBox, currentMarkers.zoomlevel)) {
      reinitOneMarker(currentMarkers, marker).then((value) {
        requestRepaint();
      });
    }
  }

  @override
  void addMarkers(Iterable<Marker<T>> markers) {
    List<Marker<T>> toInitialize = [];
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    for (var marker in markers) {
      _markers.add(marker);
      if (currentMarkers != null && marker.shouldPaint(currentMarkers.boundingBox, currentMarkers.zoomlevel)) {
        toInitialize.add(marker);
      }
    }
    if (toInitialize.isNotEmpty && currentMarkers != null) {
      unawaited(_reinitMarkers(currentMarkers, toInitialize));
    }
  }

  @override
  void markerChanged(Marker<T> marker) {
    assert(marker.key != null, "Marker must have a key for default MarkerDatastore");
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    if (currentMarkers != null && marker.shouldPaint(currentMarkers.boundingBox, currentMarkers.zoomlevel)) {
      reinitOneMarker(currentMarkers, marker).then((value) {
        requestRepaint();
      });
    }
  }

  /// Do not forget to call setRepaint()
  @override
  void removeMarker(Marker<T> marker) {
    _markers.remove(marker);
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    if (currentMarkers != null) {
      currentMarkers._initializedMarkers.remove(marker);
      bool removed = currentMarkers._cachedMarkers.remove(marker);
      if (removed) requestRepaint();
    }
    marker.dispose();
  }

  void removeByKey(T key) {
    Marker<T>? marker = _markers.firstWhereOrNull((marker) => marker.key == key);
    if (marker != null) {
      _CurrentMarkers<T>? currentMarkers = _currentMarkers;
      if (currentMarkers != null) {
        currentMarkers._initializedMarkers.remove(marker);
        bool removed = currentMarkers._cachedMarkers.remove(marker);
        if (removed) requestRepaint();
      }
      marker.dispose();
    }
  }

  /// Do not forget to call setRepaint()
  @override
  void clearMarkers() {
    for (var marker in _markers) {
      marker.dispose();
    }
    _markers.clear();
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    if (currentMarkers != null) {
      currentMarkers._initializedMarkers.clear();
      currentMarkers._cachedMarkers.clear();
      requestRepaint();
    }
  }

  Marker<T>? getMarker(T key) {
    return _markers.firstWhereOrNull((marker) => marker.key == key);
  }

  List<Marker<T>> getAllMarkers() {
    return _markers.toList();
  }

  @override
  List<Marker<T>> getTappedMarkers(TapEvent event) {
    List<Marker<T>> tappedMarkers = [];
    _CurrentMarkers<T>? currentMarkers = _currentMarkers;
    if (currentMarkers != null) {
      for (var marker in currentMarkers._cachedMarkers) {
        if (marker.isTapped(event)) tappedMarkers.add(marker);
      }
    }
    return tappedMarkers;
  }

  @override
  void dispose() {
    super.dispose();
    mapModel.unregisterMarkerDatastore(this);
    _currentMarkers = null;
    for (var value in _markers) {
      value.dispose();
    }
    _markers.clear();
    _disposed = true;
  }

  bool get disposed => _disposed;
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentMarkers<T> {
  /// All initialized markers which can be painted at the current zoomlevel but which may be outside of the current bounding box
  final Set<Marker<T>> _initializedMarkers = {};

  /// The markers which are currently eligible to paint on screen
  final Set<Marker<T>> _cachedMarkers = {};

  final int zoomlevel;

  final BoundingBox boundingBox;

  final PixelProjection projection;

  bool stop = false;

  _CurrentMarkers({required this.projection, required this.zoomlevel, required this.boundingBox});
}
