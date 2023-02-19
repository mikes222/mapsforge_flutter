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

  /// how large to extend a bounding area. When retrieving markers we extend
  /// the bounding area a bit. By doing so we retrieve a bit more markers than
  /// actually needed right now but we do not need to retrieve markers again
  /// as long as the view does not extend the extended bounding area by
  /// moving the map outside. This saves cpu. Measurements in meters.
  final int extendMeters;

  MarkerDataStore({this.extendMeters = 5000});

  /// returns the markers to draw for the given [boundary]. If this method needs more time return an empty list and call [setRepaint()] when finished.
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

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  void addMarker(Marker marker) {
    _markers.add(marker);
    if (_previousBoundingBox != null &&
        marker.shouldPaint(_previousBoundingBox!, _previousZoomLevel))
      _previousMarkers.add(marker);
  }

  /// Updates the marker. The marker was already updated but the position changed so it may not be in the _previousMarkers list
  void updateMarker(Marker marker) {
    if (_previousBoundingBox != null &&
        marker.shouldPaint(_previousBoundingBox!, _previousZoomLevel) &&
        !_previousMarkers.contains(marker))
      _previousMarkers.add(marker);
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

  List<Marker> getAllMarkers() => _markers;

  @override
  List<Marker> isTapped(TapEvent tapEvent) {
    return _previousMarkers
        .where((element) => element.isTapped(tapEvent))
        .toList();
  }
}
