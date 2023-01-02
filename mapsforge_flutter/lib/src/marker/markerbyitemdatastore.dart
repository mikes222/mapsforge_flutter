import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';

///
/// Holds a collection of markers. Marker could mark a POI (e.g. restaurants)
/// or ways (e.g. special interest areas). Use this class if you often
/// access the markers by their item. This is the case if you want to change
/// the rendering of the marker.
///
class MarkerByItemDataStore extends IMarkerDataStore {
  final Map<dynamic, Marker> _markers = {};

  BoundingBox? _previousBoundingBox;

  int _previousZoomLevel = -1;

  List<Marker> _previousMarkers = [];

  /// how large to extend a bounding area. When retrieving markers we extend
  /// the bounding area a bit. By doing so we retrieve a bit more markers than
  /// actually needed right now but we do not need to retrieve markers again
  /// as long as the view does not extend the extended bounding area by
  /// moving the map outside. This saves cpu. Measurements in meters.
  final int extendMeters;

  MarkerByItemDataStore({this.extendMeters = 5000});

  /// returns the markers to draw for the given [boundary]. If this method
  /// needs more time return an empty list and call [setRepaint()] when finished.
  @override
  List<Marker> getMarkersToPaint(BoundingBox boundary, int zoomLevel) {
    BoundingBox extended = boundary.extendMeters(extendMeters);
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

  /// This method will be called if boundary or zoomlevel changes to give the
  /// implementation the chance to replace/retrieve markers for the new
  /// boundary/zoomlevel.
  /// If this method changes something asynchronously it must call
  /// [setRepaint] afterwards.
  void retrieveMarkersFor(BoundingBox boundary, int zoomLevel) {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    clearMarkers();
  }

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  void addMarker(Marker marker) {
    _markers[marker.item] = marker;
    if (_previousBoundingBox != null &&
        marker.shouldPaint(_previousBoundingBox!, _previousZoomLevel))
      _previousMarkers.add(marker);
  }

  /// Do not forget to call setRepaint()
  void removeMarker(Marker marker) {
    _markers.removeWhere((key, value) => value == marker);
    marker.dispose();
    _previousMarkers.remove(marker);
  }

  /// Do not forget to call setRepaint()
  void clearMarkers() {
    _markers.values.forEach((marker) {
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

  /// Finds the old marker with the given item and replaces it with the new marker. Do not forget to call setRepaint()
  void replaceMarker(var item, BasicMarker newMarker) {
    Marker? oldMarker = getMarkerWithItem(item);
    if (oldMarker != null) {
      _markers.remove(item);
      _previousMarkers.remove(oldMarker);
      oldMarker.dispose();
    }
    _markers[item] = newMarker;
    if (_previousBoundingBox != null &&
        newMarker.shouldPaint(_previousBoundingBox!, _previousZoomLevel))
      _previousMarkers.add(newMarker);
  }

  /// remove the marker with the given [item]. Do not forget to call setRepaint()
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

  Iterable getAllItems() {
    return _markers.keys;
  }
}
