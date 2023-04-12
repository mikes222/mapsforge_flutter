import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

/// Draws an normally open path as marker. Note that isTapped() returns
/// always false.
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
  void render(MarkerCallback markerCallback) {
    if (_zoom == markerCallback.mapViewPosition.zoomLevel) {
      markerCallback.flutterCanvas.uiCanvas.save();
      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      markerCallback.flutterCanvas.uiCanvas
          .translate(_leftUpperX - leftUpper.x, _leftUpperY - leftUpper.y);
      //if (fill != null) markerCallback.renderPath(mapPath!, fill!);
      markerCallback.renderPath(
          mapPath!, getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
      markerCallback.flutterCanvas.uiCanvas.restore();
    } else {
      mapPath?.clear();
      _points.clear();
      _zoom = markerCallback.mapViewPosition.zoomLevel;
      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      path.forEach((latLong) {
        Mappoint mappoint = Mappoint(
            markerCallback.mapViewPosition.projection
                .longitudeToPixelX(latLong.longitude),
            markerCallback.mapViewPosition.projection
                .latitudeToPixelY(latLong.latitude));
        double y = mappoint.y - leftUpper.y;
        double x = mappoint.x - leftUpper.x;

        _points.add(mappoint);

        if (mapPath!.isEmpty())
          mapPath!.moveTo(x, y);
        else
          mapPath!.lineTo(x, y);
      });
      _leftUpperX = leftUpper.x;
      _leftUpperY = leftUpper.y;
      markerCallback.renderPath(
          mapPath!, getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
    }
  }

  int indexOfTappedPath(TapEvent tapEvent) {
    for (int idx = 0; idx < _points.length - 1; ++idx) {
      double distance = LatLongUtils.distanceSegmentPoint(
          _points[idx].x,
          _points[idx].y,
          _points[idx + 1].x,
          _points[idx + 1].y,
          tapEvent.mapPixelMappoint.x,
          tapEvent.mapPixelMappoint.y);
      if (distance <= getStrokeWidth()) return idx;
    }
    return -1;
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return indexOfTappedPath(tapEvent) >= 0;
  }
}
