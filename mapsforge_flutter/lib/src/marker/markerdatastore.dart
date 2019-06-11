import 'package:mapsforge_flutter/src/marker/basicmarker.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

class MarkerDataStore {
  final List<BasicMarker> markers = List();

  bool _needsRepaint = false;

  List<BasicMarker> getMarkers(BoundingBox boundary, int zoomLevel) {
    return markers.where((marker) => marker.minZoomLevel <= zoomLevel && marker.maxZoomLevel >= zoomLevel).toList();
  }

  void dispose() {
    markers.forEach((marker) {
      marker.dispose();
    });
  }

  void setRepaint() {
    _needsRepaint = true;
  }

  void resetRepaint() {
    _needsRepaint = false;
  }

  bool get needsRepaint => _needsRepaint;
}
