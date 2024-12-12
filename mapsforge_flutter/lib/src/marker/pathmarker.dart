import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

import '../graphics/implementation/fluttercanvas.dart';

/// Draws an normally open path as marker.
class PathMarker<T> extends Marker<T> with PaintMixin {
  List<ILatLong> path = [];

  MapPath? mapPath;

  List<Mappoint> _points = [];

  int _zoom = -1;

  double _leftUpperX = -1;

  double _leftUpperY = -1;

  PathMarker({
    display = Display.ALWAYS,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    item,
    double strokeWidth = 1.0,
    int strokeColor = 0xff000000,
    required DisplayModel displayModel,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(strokeWidth >= 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
        ) {
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL);
    setStrokeColorFromNumber(strokeColor);
    setStrokeWidth(strokeWidth * displayModel.getScaleFactor());
    mapPath = GraphicFactory().createPath();
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
    mapPath?.clear();
    _zoom = -1;
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void render(MapCanvas mapCanvas, MarkerContext markerContext) {
    if (_zoom == markerContext.zoomLevel) {
      (mapCanvas as FlutterCanvas).uiCanvas.save();
      mapCanvas.uiCanvas.translate(_leftUpperX - markerContext.mapCenter.x,
          _leftUpperY - markerContext.mapCenter.y);
      //if (fill != null) markerCallback.renderPath(mapPath!, fill!);
      mapCanvas.drawPath(mapPath!, getStrokePaint(markerContext.zoomLevel));
      mapCanvas.uiCanvas.restore();
    } else {
      mapPath?.clear();
      _points.clear();
      _zoom = markerContext.zoomLevel;
      path.forEach((latLong) {
        Mappoint mappoint = markerContext.projection.latLonToPixel(latLong);
        double y = mappoint.y - markerContext.mapCenter.y;
        double x = mappoint.x - markerContext.mapCenter.x;

        _points.add(mappoint);

        if (mapPath!.isEmpty())
          mapPath!.moveTo(x, y);
        else
          mapPath!.lineTo(x, y);
      });
      _leftUpperX = markerContext.mapCenter.x;
      _leftUpperY = markerContext.mapCenter.y;
      mapCanvas.drawPath(mapPath!, getStrokePaint(markerContext.zoomLevel));
    }
  }

  int indexOfTappedPath(TapEvent tapEvent) {
    Mappoint tapped = tapEvent.projection.latLonToPixel(tapEvent);
    for (int idx = 0; idx < _points.length - 1; ++idx) {
      double distance = LatLongUtils.distanceSegmentPoint(
          _points[idx].x,
          _points[idx].y,
          _points[idx + 1].x,
          _points[idx + 1].y,
          tapped.x,
          tapped.y);
      if (distance <= getStrokeWidth()) return idx;
    }
    return -1;
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return indexOfTappedPath(tapEvent) >= 0;
  }
}
