import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/linesegment.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/waydecorator.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

/// Draws Text along a polygon. Does NOT draw the polygon. Use [PolygonMarker] in conjunction with this marker.
class PolygonTextMarker<T> extends BasicMarker<T> with TextMixin, PaintMixin {
  static final _log = new Logger('PolygonMarker');

  List<ILatLong> path = [];

  BoundingBox? _boundingBox;

  int? fillColor;

  final double strokeWidth;

  final int strokeColor;

  final String caption;

  double fontSize;

  int _zoom = -1;

  double _leftUpperX = -1;

  double _leftUpperY = -1;

  LineString? _lineString;

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
    disposeTextMixin();
    disposePaintMixin();
    super.dispose();
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
    _boundingBox = BoundingBox.fromLatLongs(path);
  }

  Future<void> initResources() async {
    initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    fontSize = this.fontSize;
    setStrokeColorFromNumber(this.strokeColor);
    if (fillColor != null) setFillColorFromNumber(this.fillColor!);
    setStrokeWidth(this.strokeWidth);
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
      Mappoint origin = Mappoint(markerCallback.mapViewPosition.leftUpper!.x,
          markerCallback.mapViewPosition.leftUpper!.y);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel));
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getFillPaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel));
    } else {
      _lineString = LineString();
      double? prevX = null;
      double? prevY = null;
      path.forEach((latLong) {
        double y = markerCallback.mapViewPosition.projection!
            .latitudeToPixelY(latLong.latitude);
        double x = markerCallback.mapViewPosition.projection!
            .longitudeToPixelX(latLong.longitude);

        if (prevX != null && prevY != null) {
          LineSegment segment =
              LineSegment(Mappoint(prevX!, prevY!), Mappoint(x, y));
          _lineString!.segments.add(segment);
        }
        prevX = x;
        prevY = y;
      });

      double textWidth = getTextPaint(markerCallback.mapViewPosition.zoomLevel)
          .getTextWidth(caption);
      _lineString = WayDecorator.reducePathForText(_lineString!, textWidth);
      // _lineString!.segments.forEach((element) {
      //   print(
      //       "Segment ${element.end.x - element.start.x} / ${element.end.y - element.start.y} for textWidth $textWidth - $element $caption");
      // });

      Mappoint origin = Mappoint(markerCallback.mapViewPosition.leftUpper!.x,
          markerCallback.mapViewPosition.leftUpper!.y);
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel));
      markerCallback.renderPathText(
          caption,
          _lineString!,
          origin,
          getFillPaint(markerCallback.mapViewPosition.zoomLevel),
          getTextPaint(markerCallback.mapViewPosition.zoomLevel));

      _zoom = markerCallback.mapViewPosition.zoomLevel;
    }
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    ILatLong latLong = tapEvent.projection.pixelToLatLong(
        tapEvent.x + tapEvent.leftUpperX, tapEvent.y + tapEvent.leftUpperY);
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, latLong);
  }
}
