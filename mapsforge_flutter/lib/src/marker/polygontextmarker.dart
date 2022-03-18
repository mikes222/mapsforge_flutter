import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/linesegment.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';
import 'package:mapsforge_flutter/src/utils/latlongutils.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

/// Draws Text along a polygon
class PolygonTextMarker<T> extends BasicMarker<T> with TextMixin {
  static final _log = new Logger('PolygonMarker');

  List<ILatLong> path = [];

  int? fillColor;

  final double strokeWidth;

  final int strokeColor;

  final String caption;

  final double fontSize;

  PolygonTextMarker({
    required this.caption,
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    this.fontSize = 10,
    this.fillColor,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        assert(strokeWidth >= 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
        ) {}

  @override
  void dispose() {
    mixinDispose();
    super.dispose();
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
  }

  @override
  Future<void> initResources(SymbolCache? symbolCache) async {
    await super.initResources(symbolCache);
    initTextMixin();
    fontSize = this.fontSize;
    stroke!.setColorFromNumber(this.strokeColor);
    if (fillColor != null) fill!.setColorFromNumber(this.fillColor!);
    stroke!.setStrokeWidth(this.strokeWidth);
  }

  @override
  bool shouldPaint(BoundingBox? boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void renderBitmap(MarkerCallback markerCallback, int zoomLevel) {
    LineString lineString = LineString();
    double? prevX = null;
    double? prevY = null;
    path.forEach((latLong) {
      double y = markerCallback.mapViewPosition.projection!
          .latitudeToPixelY(latLong.latitude);
      double x = markerCallback.mapViewPosition.projection!
          .longitudeToPixelX(latLong.longitude);

      if (prevX != null && prevY != null) {
        LineSegment segment =
            new LineSegment(Mappoint(prevX!, prevY!), Mappoint(x, y));
        lineString.segments.add(segment);
      }
      prevX = x;
      prevY = y;
    });
    LineSegment segment = new LineSegment(
        lineString.segments.last.end, lineString.segments.first.start);
    lineString.segments.add(segment);

    Mappoint origin = Mappoint(markerCallback.mapViewPosition.leftUpper!.x,
        markerCallback.mapViewPosition.leftUpper!.y);
    markerCallback.renderPathText(caption, lineString, origin, stroke!);
    markerCallback.renderPathText(caption, lineString, origin, fill!);
  }

  @override
  bool isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    ILatLong latLong = mapViewPosition.projection!.pixelToLatLong(
        tappedX + mapViewPosition.leftUpper!.x,
        tappedY + mapViewPosition.leftUpper!.y);
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, latLong);
  }
}
