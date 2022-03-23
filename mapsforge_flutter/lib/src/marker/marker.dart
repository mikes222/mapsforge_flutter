import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';

class Marker<T> {
  final Display display;

  int minZoomLevel;

  int maxZoomLevel;

  /// the item this marker represents.
  ///
  /// This property is NOT used by mapsforge.
  T? item;

  Marker(
      {this.display = Display.ALWAYS,
      this.minZoomLevel = 0,
      this.maxZoomLevel = 65535,
      this.item});

  ///
  /// Renders this object. Called by markerPointer -> markerRenderer
  ///
  void render(MarkerCallback markerCallback) {}

  /// returns true if this marker is within the visible boundary and therefore should be painted. Since the initResources() is called
  /// only if shouldPoint() returns true, do not test for available resources here.
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return display != Display.NEVER &&
        minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel;
  }

  /// returns true if the position specified by [tapEvent] is in the area of
  /// this marker. Note that tapEvent represents the position at the time the
  /// tap has been executed.
  bool isTapped(TapEvent tapEvent) {
    return false;
  }

  void dispose() {}
}
