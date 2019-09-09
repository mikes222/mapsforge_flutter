import 'dart:math';

import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttermatrix.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'markercallback.dart';

class MarkerContext implements MarkerCallback {
  final FlutterCanvas flutterCanvas;

  final GraphicFactory graphicFactory;

  final MapViewPosition mapViewPosition;

  MarkerContext(this.flutterCanvas, this.graphicFactory, this.mapViewPosition);

  void renderBitmap(Bitmap bitmap, double latitude, double longitude, double offsetX, double offsetY, double rotation, MapPaint paint) {
    double y = mapViewPosition.mercatorProjection.latitudeToPixelY(latitude);
    double x = mapViewPosition.mercatorProjection.longitudeToPixelX(longitude);
    FlutterMatrix matrix;
    if (rotation != null && rotation != 0) {
      matrix = FlutterMatrix();
      matrix.rotate(rotation / 180 * pi, pivotX: bitmap.getWidth() / 2, pivotY: bitmap.getHeight() / 2);
    }
    flutterCanvas.drawBitmap(
        bitmap: bitmap,
        left: x + offsetX - mapViewPosition.leftUpper.x,
        top: y + offsetY - mapViewPosition.leftUpper.y,
        matrix: matrix,
        paint: paint);
  }

  void renderText(String caption, ILatLong latLong, double offsetX, double offsetY, MapPaint stroke) {
    assert(stroke != null);
    assert(caption != null);
    assert(latLong != null);
    assert(offsetX != null);
    assert(offsetY != null);
    Mappoint mappoint = mapViewPosition.mercatorProjection.getPixelRelativeToLeftUpper(latLong, mapViewPosition.leftUpper);
//    print(
//        "rendering caption $caption at latLong ${latLong.toString()}, ${mappoint.toString()} and leftUpper ${mapViewPosition.leftUpper.toString()}");
    flutterCanvas.drawText(caption, (mappoint.x + offsetX).toInt(), (mappoint.y + offsetY).toInt(), stroke);
  }

  @override
  void renderPath(MapPath path, MapPaint paint) {
    flutterCanvas.drawPath(path, paint);
  }

  void renderCircle(double latitude, double longitude, double radius, MapPaint paint) {
    double y = mapViewPosition.mercatorProjection.latitudeToPixelY(latitude);
    double x = mapViewPosition.mercatorProjection.longitudeToPixelX(longitude);
    flutterCanvas.drawCircle((x - mapViewPosition.leftUpper.x).toInt(), (y - mapViewPosition.leftUpper.y).toInt(), radius.toInt(), paint);
  }

  @override
  void renderRect(MapRect rect, MapPaint paint) {
    flutterCanvas.drawRect(rect, paint);
  }
}
