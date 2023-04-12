import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/paragraph_cache.dart';
import 'package:mapsforge_flutter/src/model/linesegment.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/paintelements/waydecorator.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

/// Draws Text along a polygon. Does NOT draw the polygon. Use [PolygonMarker] in conjunction with this marker.
class PolygonTextMarker<T> extends BasicMarker<T> with TextMixin, PaintMixin {
  List<ILatLong> path = [];

  BoundingBox? _boundingBox;

  final String caption;

  int _zoom = -1;

  double _leftUpperX = -1;

  double _leftUpperY = -1;

  LineString? _lineString;

  /// The maximum width of a text as defined in the displaymodel
  final double maxTextWidth;

  PolygonTextMarker({
    required this.caption,
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    double fontSize = 10,
    int? fillColor,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    this.maxTextWidth = 200,
    required DisplayModel displayModel,
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
        ) {
    initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setStrokeColorFromNumber(strokeColor);
    if (fillColor != null)
      setFillColorFromNumber(fillColor);
    else
      setFillColor(Colors.transparent);
    setFontSize(fontSize * displayModel.getFontScaleFactor());
    setStrokeWidth(strokeWidth * displayModel.getFontScaleFactor());
  }

  @override
  void dispose() {
    disposeTextMixin();
    disposePaintMixin();
    super.dispose();
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
    _boundingBox = BoundingBox.fromLatLongs(path);
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    if (_boundingBox == null) return false;
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        _boundingBox!.intersects(boundary);
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    if (_zoom == markerCallback.mapViewPosition.zoomLevel) {
      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      Mappoint origin = Mappoint(leftUpper.x, leftUpper.y);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel),
          maxTextWidth);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getFillPaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel),
          maxTextWidth);
    } else {
      _lineString = LineString();
      double? prevX = null;
      double? prevY = null;
      path.forEach((latLong) {
        double y = markerCallback.mapViewPosition.projection
            .latitudeToPixelY(latLong.latitude);
        double x = markerCallback.mapViewPosition.projection
            .longitudeToPixelX(latLong.longitude);

        if (prevX != null && prevY != null) {
          LineSegment segment =
              LineSegment(Mappoint(prevX!, prevY!), Mappoint(x, y));
          _lineString!.segments.add(segment);
        }
        prevX = x;
        prevY = y;
      });

      ParagraphEntry entry = ParagraphCache().getEntry(
          caption,
          getTextPaint(markerCallback.mapViewPosition.zoomLevel),
          getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
          maxTextWidth);
      _lineString =
          WayDecorator.reducePathForText(_lineString!, entry.getWidth());
      // _lineString!.segments.forEach((element) {
      //   print(
      //       "Segment ${element.end.x - element.start.x} / ${element.end.y - element.start.y} for textWidth $textWidth - $element $caption");
      // });

      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      Mappoint origin = Mappoint(leftUpper.x, leftUpper.y);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel),
          maxTextWidth);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getFillPaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel),
          maxTextWidth);

      _zoom = markerCallback.mapViewPosition.zoomLevel;
    }
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return LatLongUtils.contains(path, tapEvent);
  }
}
