import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

import '../graphics/implementation/fluttercanvas.dart';
import '../graphics/mapcanvas.dart';

/// A marker which uses flutter Icons. The size can be set with the [fontSize] parameter. Currently there is
/// no way to set the position of the marker (to e.g. above the position) so an icon which is suitable for
/// being centered should be used.
class IconMarker<T> extends BasicPointMarker<T> with PaintMixin {
  final IconData icon;
  final Color? color;
  final double fontSize;
  final List<Shadow>? shadows;

  IconMarker({
    required this.icon,
    required this.color,
    Display super.display,
    super.minZoomLevel,
    super.maxZoomLevel,
    this.shadows,
    this.fontSize = 26,
    super.item,
    super.markerCaption,
    required ILatLong center,
    required DisplayModel displayModel,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        super(
          latLong: center,
        );

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        boundary.contains(latLong.latitude, latLong.longitude);
  }

  @override
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {
    final iconPosition = Offset(
      (mappoint.x - markerContext.mapCenter.x),
      (mappoint.y - markerContext.mapCenter.y),
    );

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: icon.fontFamily,
          color: color,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint((flutterCanvas as FlutterCanvas).uiCanvas, iconPosition);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    Mappoint p2 = tapEvent.projection.latLonToPixel(latLong);
    Mappoint tapped = tapEvent.projection.latLonToPixel(tapEvent);

    return p2.distance(tapped) <= fontSize;
  }
}
