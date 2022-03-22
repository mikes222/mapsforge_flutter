import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants) or ways (e.g. special interest areas). Use this class if you often access the markers by their item.
///
class MarkerByItemDataStore extends IMarkerDataStore {
  final Map<dynamic, Marker> _markers = {};

  BoundingBox? _previousBoundingBox;

  int? _previousZoomLevel;

  List<Marker> _previousMarkers = [];

  MarkerByItemDataStore();

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
    List<Marker> markersToDraw = _markers.values
        .where((marker) => marker.shouldPaint(extended, zoomLevel))
        .toList();
    _previousMarkers = markersToDraw;
    return markersToDraw;
  }

  /// This method will be called if boundary or zoomlevel changes to give the implementation the chance to replace/retrieve markers for the new boundary/zoomlevel.
  /// If this method changes something asynchronously it must call [setRepaint] afterwards.
  void retrieveMarkersFor(BoundingBox boundary, int zoomLevel) {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    clearMarkers();
  }

  void addMarker(Marker marker) {
    _markers[marker.item] = marker;
    _previousZoomLevel = -1;
  }

  void removeMarker(Marker marker) {
    _markers.remove(marker);
    marker.dispose();
    _previousMarkers.remove(marker);
  }

  void clearMarkers() {
    _markers.values.forEach((marker) {
      marker.dispose();
    });
    _markers.clear();
    _previousMarkers.clear();
  }

  @override
  List<Marker> isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return _previousMarkers
        .where((element) => element.isTapped(mapViewPosition, tappedX, tappedY))
        .toList();
  }

  /// Finds the old marker with the given item and replaces it with the new marker
  void replaceMarker(var item, BasicMarker newMarker) {
    Marker? oldMarker = getMarkerWithItem(item);
    if (oldMarker != null) {
      _markers.remove(item);
      oldMarker.dispose();
    }
    _markers[item] = newMarker;
    _previousZoomLevel = -1;
  }

  /// remove the marker with the given [item]
  void removeMarkerWithItem(var item) {
    Marker? oldMarker = getMarkerWithItem(item);
    if (oldMarker != null) {
      _markers.remove(item);
      oldMarker.dispose();
      _previousMarkers.remove(oldMarker);
    }
  }

  Marker? getMarkerWithItem(var item) {
    return _markers[item];
  }
}
