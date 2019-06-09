import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/utils/mercatorprojection.dart';

import 'markercallback.dart';

class MarkerContext implements MarkerCallback {
  final FlutterCanvas flutterCanvas;

  final GraphicFactory graphicFactory;

  final MapViewPosition mapViewPosition;

  MarkerContext(this.flutterCanvas, this.graphicFactory, this.mapViewPosition);

  void renderBitmap(Bitmap bitmap, double latitude, double longitude, double offsetX, double offsetY) {
    double y = mapViewPosition.mercatorProjection.latitudeToPixelY(latitude);
    double x = mapViewPosition.mercatorProjection.longitudeToPixelX(longitude);
    flutterCanvas.drawBitmap(
        bitmap: bitmap, left: x + offsetX - mapViewPosition.leftUpper.x, top: y + offsetY - mapViewPosition.leftUpper.y);
  }

  void renderText(String caption, double latitude, double longitude, double offsetX, double offsetY, MapPaint stroke, double fontSize) {
    double y = mapViewPosition.mercatorProjection.latitudeToPixelY(latitude);
    double x = mapViewPosition.mercatorProjection.longitudeToPixelX(longitude);
    flutterCanvas.drawText(caption, (x + offsetX - mapViewPosition.leftUpper.x).toInt(),
        (y + offsetY - mapViewPosition.leftUpper.y).toInt(), fontSize, stroke);
  }
}
