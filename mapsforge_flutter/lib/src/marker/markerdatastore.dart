import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/marker/basicmarker.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants) or ways (e.g. special interest areas)
///
class MarkerDataStore with ChangeNotifier {
  final List<BasicMarker> markers = List();

  bool _needsRepaint = false;

  List<BasicMarker> getMarkers(BoundingBox boundary, int zoomLevel) {
    return markers.where((marker) => marker.shouldPaint(boundary, zoomLevel)).toList();
  }

  @override
  @mustCallSuper
  void dispose() {
    markers.forEach((marker) {
      marker.dispose();
    });
    super.dispose();
  }

  void setRepaint() {
    _needsRepaint = true;
    notifyListeners();
  }

  void resetRepaint() {
    _needsRepaint = false;
  }

  bool get needsRepaint => _needsRepaint;
}
