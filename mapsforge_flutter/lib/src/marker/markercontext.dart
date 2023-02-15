import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttermatrix.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterrect.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'markercallback.dart';

class MarkerContext implements MarkerCallback {
  @override
  final FlutterCanvas flutterCanvas;

  @override
  final MapViewPosition mapViewPosition;

  /// The factor to scale down the map. With [DisplayModel.deviceScaleFactor] one can scale up the view and make it bigger. With this value
  /// one can scale down the view and make the resolution of the map better. This comes with the cost of increased tile image sizes and thus increased time for creating the tile-images
  @override
  final double viewScaleFactor;

  const MarkerContext(
      this.flutterCanvas, this.mapViewPosition, this.viewScaleFactor);

  @override
  void renderBitmap(ResourceBitmap bitmap, double latitude, double longitude,
      double offsetX, double offsetY, double rotation, MapPaint paint) {
    double y = mapViewPosition.projection!.latitudeToPixelY(latitude);
    double x = mapViewPosition.projection!.longitudeToPixelX(longitude);
    FlutterMatrix? matrix;
    if (rotation != 0) {
      matrix = FlutterMatrix();
      matrix.rotate(rotation / 180 * pi,
          pivotX: -bitmap.getWidth() / 2, pivotY: -bitmap.getHeight() / 2);
    }
    flutterCanvas.drawBitmap(
        bitmap: bitmap,
        left: x + offsetX - mapViewPosition.leftUpper!.x,
        top: y + offsetY - mapViewPosition.leftUpper!.y,
        matrix: matrix,
        paint: paint);
  }

  @override
  void renderPathText(String caption, LineString lineString, Mappoint origin,
      MapPaint stroke, MapTextPaint textPaint, double maxTextWidth) {
    flutterCanvas.drawPathText(
        caption, lineString, origin, stroke, textPaint, maxTextWidth);
  }

  @override
  void renderPath(MapPath path, MapPaint paint) {
    flutterCanvas.drawPath(path, paint);
  }

  @override
  void renderCircle(
      double latitude, double longitude, double radius, MapPaint paint) {
    double y = mapViewPosition.projection!.latitudeToPixelY(latitude);
    double x = mapViewPosition.projection!.longitudeToPixelX(longitude);
    flutterCanvas.drawCircle((x - mapViewPosition.leftUpper!.x),
        (y - mapViewPosition.leftUpper!.y), radius, paint);
    // flutterCanvas.drawRect(
    //     FlutterRect(
    //         x - mapViewPosition.leftUpper!.x,
    //         y - mapViewPosition.leftUpper!.y,
    //         x - mapViewPosition.leftUpper!.x + 10,
    //         y - mapViewPosition.leftUpper!.y + 10),
    //     FlutterPaint(Paint()..color = Colors.red));
  }

  @override
  void renderRect(MapRect rect, MapPaint paint) {
    flutterCanvas.drawRect(rect, paint);
  }
}
