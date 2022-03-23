import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/marker/imarkerdatastore.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants) or ways (e.g. special interest areas)
///
class MarkerDataStore extends IMarkerDataStore {
  final List<Marker> _markers = [];

  BoundingBox? _previousBoundingBox;

  int _previousZoomLevel = -1;

  List<Marker> _previousMarkers = [];

  MarkerDataStore();

  /// returns the markers to draw for the given [boundary]. If this method needs more time return an empty list and call [setRepaint()] when finished.
  @override
  List<Marker> getMarkersToPaint(BoundingBox boundary, int zoomLevel) {
    BoundingBox extended = boundary.extendMeters(1000);
    if (_previousBoundingBox != null &&
        _previousBoundingBox!.containsBoundingBox(boundary) &&
        zoomLevel == _previousZoomLevel) {
      return _previousMarkers;
    }
    retrieveMarkersFor(extended, zoomLevel);
    _previousBoundingBox = extended;
    _previousZoomLevel = zoomLevel;
    List<Marker> markersToDraw = _markers
        .where((marker) => marker.shouldPaint(extended, zoomLevel))
        .toList();
    _previousMarkers = markersToDraw;
    return markersToDraw;
  }

  /// This method will be called if boundary or zoomlevel changes to give the implementation the chance to replace/retrieve markers for the new boundary/zoomlevel.
  /// If this method changes something asynchronously it must call [setRepaint] afterwards.
  void retrieveMarkersFor(BoundingBox boundary, int zoomLevel) {}

  @override
  void dispose() {
    super.dispose();
    clearMarkers();
  }

  void addMarker(Marker marker) {
    _markers.add(marker);
    _previousZoomLevel = -1;
  }

  void removeMarker(Marker marker) {
    _markers.remove(marker);
    marker.dispose();
    _previousMarkers.remove(marker);
  }

  void clearMarkers() {
    _markers.forEach((marker) {
      marker.dispose();
    });
    _markers.clear();
    _previousMarkers.clear();
  }

  @override
  List<Marker> isTapped(TapEvent tapEvent) {
    return _previousMarkers
        .where((element) => element.isTapped(tapEvent))
        .toList();
  }
}
