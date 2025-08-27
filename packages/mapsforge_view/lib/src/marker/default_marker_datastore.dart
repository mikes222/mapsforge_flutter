import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:mapsforge_view/marker.dart';

class DefaultMarkerDatastore<T> extends MarkerDatastore<T> {
  final Map<T, Marker<T>> _markers = {};

  final Map<T, Marker<T>> _cachedMarkers = {};

  DefaultMarkerDatastore({required super.zoomlevelRange, super.extendMeters = 5000});

  @override
  Future<void> askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) async {
    await super.askChangeZoomlevel(zoomlevel, boundingBox, projection);
    for (var marker in _markers.values) {
      await marker.changeZoomlevel(zoomlevel, projection);
    }
  }

  @override
  void retrieveMarkersFor(BoundingBox boundingBox, int zoomlevel) {
    _cachedMarkers.clear();
    for (var marker in _markers.values) {
      if (marker.shouldPaint(boundingBox, zoomlevel)) {
        _cachedMarkers[marker.key!] = marker;
      }
    }
  }

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  @override
  void addMarker(Marker<T> marker) {
    assert(marker.key != null, "Marker must have an item in default MarkerDatastore");
    _markers[marker.key!] = marker;
    if (cachedBoundingBox != null && marker.shouldPaint(cachedBoundingBox!, cachedZoomlevel)) _cachedMarkers[marker.key!] = marker;
  }

  /// Do not forget to call setRepaint()
  void removeMarker(Marker<T> marker) {
    _markers.remove(marker.key);
    marker.dispose();
    _cachedMarkers.remove(marker.key);
  }

  /// Do not forget to call setRepaint()
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

  @override
  List<Marker<T>> retrieveMarkersToPaint() {
    return _markers.values.toList();
  }
}
