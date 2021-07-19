import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/marker/basicmarker.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants) or ways (e.g. special interest areas)
///
class MarkerDataStore with ChangeNotifier {
  static final _log = new Logger('MarkerDataStore');

  final List<BasicMarker> _markers = [];

  final Set<BasicMarker> _markersNeedInit = Set();

  //bool _needsRepaint = false;

  /// returns the markers to draw for the given [boundary]. If this method needs more time return an empty list and call [setRepaint()] when finished.
  List<BasicMarker> getMarkers(
      GraphicFactory graphicFactory, BoundingBox boundary, int zoomLevel) {
    List<BasicMarker> markers = _markers
        .where((marker) => marker.shouldPaint(boundary, zoomLevel))
        .toList();
    List<BasicMarker> markersToInit =
        markers.where((element) => _markersNeedInit.contains(element)).toList();
    _markersNeedInit.removeAll(markersToInit);
    if (markersToInit.length > 0) {
      _initMarkers(graphicFactory, markersToInit);
      return [];
    }
    return markers;
  }

  void _initMarkers(
      GraphicFactory graphicFactory, List<BasicMarker> markersToInit) async {
    _log.info("Initializing ${markersToInit.length} markers now");
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

  @protected
  void setRepaint() {
    //_needsRepaint = true;
    notifyListeners();
  }

  void resetRepaint() {
    //_needsRepaint = false;
  }

  //bool get needsRepaint => _needsRepaint;

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

  List<BasicMarker> isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return _markers
        .where((element) => element.isTapped(mapViewPosition, tappedX, tappedY))
        .toList();
  }

  void replaceMarkerWithItem(var item, BasicMarker marker) {
    int idx = _markers.indexWhere((marker) => marker.item == item);
    if (idx == -1) return;
    _markersNeedInit.remove(_markers[idx]);
    _markers[idx] = marker;
    _markersNeedInit.add(marker);
  }
}
