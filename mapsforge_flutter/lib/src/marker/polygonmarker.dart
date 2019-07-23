import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PolygonMarker<T> extends BasicMarker<T> {
  List<ILatLong> path = List();

  MapPaint fill;

  double fillWidth;

  int fillColor;

  PolygonMarker({
    display = Display.ALWAYS,
    latLong,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    strokeWidth = 1.0,
    strokeColor = 0xff000000,
    imageColor = 0xff000000,
    rotation,
    item,
    this.fillWidth = 1.0,
    this.fillColor = 0x40000000,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(strokeWidth >= 0),
        assert(fillWidth >= 0),
        assert(strokeColor != null),
        assert(fillColor != null),
        assert(imageColor != null),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          strokeWidth: strokeWidth,
          strokeColor: strokeColor,
          imageColor: imageColor,
          rotation: rotation,
          item: item,
          latLong: latLong,
        );

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
  }

  @override
  void initRessources(MarkerCallback markerCallback) {
    super.initRessources(markerCallback);
    if (fill == null && fillWidth > 0) {
      this.fill = markerCallback.graphicFactory.createPaint();
      this.fill.setColorFromNumber(fillColor);
      this.fill.setStyle(Style.FILL);
      this.fill.setStrokeWidth(fillWidth);
      //this.stroke.setTextSize(fontSize);
    }
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    MapPath mapPath = markerCallback.graphicFactory.createPath();

    path.forEach((latLong) {
      double y =
          markerCallback.mapViewPosition.mercatorProjection.latitudeToPixelY(latLong.latitude) - markerCallback.mapViewPosition.leftUpper.y;
      double x = markerCallback.mapViewPosition.mercatorProjection.longitudeToPixelX(latLong.longitude) -
          markerCallback.mapViewPosition.leftUpper.x;

      if (mapPath.isEmpty())
        mapPath.moveTo(x, y);
      else
        mapPath.lineTo(x, y);
    });
    mapPath.close();
    if (fill != null) markerCallback.renderPath(mapPath, fill);
    if (stroke != null) markerCallback.renderPath(mapPath, stroke);
  }
}
