import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/marker/basicmarker.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants) or ways (e.g. special interest areas)
///
class MarkerDataStore with ChangeNotifier {
  final List<BasicMarker> _markers = [];

  final List<BasicMarker> _markersNeedInit = [];

  bool _needsRepaint = false;

  List<BasicMarker> getMarkers(GraphicFactory graphicFactory, BoundingBox? boundary, int zoomLevel) {
    List<BasicMarker> markers = _markers.where((marker) => marker.shouldPaint(boundary, zoomLevel)).toList();
    List<BasicMarker> markersToInit = markers.where((element) => _markersNeedInit.contains(element)).toList();
    markersToInit.forEach((element) {
      _markersNeedInit.remove(element);
    });
    if (markersToInit.length > 0) {
      print("Initializing ${markersToInit.length} markers now");
      _initMarkers(graphicFactory, markersToInit);
    }
    return markers;
  }

  void _initMarkers(GraphicFactory graphicFactory, List<BasicMarker> markersToInit) async {
    for (BasicMarker m in markersToInit) {
      await m.initResources(graphicFactory);
    }
    setRepaint();
  }

  @override
  @mustCallSuper
  void dispose() {
    _markers.forEach((marker) {
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

  void addMarker(BasicMarker marker) {
    _markersNeedInit.add(marker);
    _markers.add(marker);
  }

  void removeMarker(BasicMarker marker) {
    _markersNeedInit.remove(marker);
    _markers.remove(marker);
  }

  void clearMarker() {
    _markersNeedInit.clear();
    _markers.clear();
  }

  List<BasicMarker> isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return _markers.where((element) => element.isTapped(mapViewPosition, tappedX, tappedY)).toList();
  }

  void replaceMarkerWithItem(var item, BasicMarker marker) {
    int idx = _markers.indexWhere((marker) => marker.item == item);
    if (idx == -1) return;
    _markersNeedInit.remove(_markers[idx]);
    _markers[idx] = marker;
    _markersNeedInit.add(marker);
  }
}
