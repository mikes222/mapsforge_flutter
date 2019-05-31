import 'dart:ui' as ui;

import 'package:mapsforge_flutter/graphics/bitmap.dart';
import 'package:mapsforge_flutter/graphics/canvas.dart';
import 'package:mapsforge_flutter/graphics/color.dart';
import 'package:mapsforge_flutter/graphics/filter.dart';
import 'package:mapsforge_flutter/graphics/matrix.dart';
import 'package:mapsforge_flutter/graphics/paint.dart';
import 'package:mapsforge_flutter/graphics/path.dart';
import 'package:mapsforge_flutter/model/dimension.dart';
import 'package:mapsforge_flutter/model/rectangle.dart';

class FlutterCanvas extends Canvas {
  final ui.Canvas canvas;

  final ui.Size size;

  FlutterCanvas(this.canvas, this.size) : assert(canvas != null);

  @override
  void destroy() {
    // TODO: implement destroy
  }

  @override
  void drawBitmap(
      {Bitmap bitmap,
      int left,
      int top,
      int srcLeft,
      int srcTop,
      int srcRight,
      int srcBottom,
      int dstLeft,
      int dstTop,
      int dstRight,
      int dstBottom,
      Matrix matrix,
      Filter filter}) {
    // TODO: implement drawBitmap
  }

  @override
  void drawCircle(int x, int y, int radius, Paint paint) {
    // TODO: implement drawCircle
  }

  @override
  void drawLine(int x1, int y1, int x2, int y2, Paint paint) {
    // TODO: implement drawLine
  }

  @override
  void drawPath(Path path, Paint paint) {
    // TODO: implement drawPath
  }

  @override
  void drawPathText(String text, Path path, Paint paint) {
    // TODO: implement drawPathText
  }

  @override
  void drawText(String text, int x, int y, Paint paint) {
    // TODO: implement drawText
  }

  @override
  void drawTextRotated(
      String text, int x1, int y1, int x2, int y2, Paint paint) {
    // TODO: implement drawTextRotated
  }

  @override
  void fillColor(Color color) {
    // TODO: implement fillColor
  }

  @override
  void fillColorFromNumber(int color) {
    ui.Paint paint = ui.Paint()..color = ui.Color(color);
    this
        .canvas
        .drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  Dimension getDimension() {
    // TODO: implement getDimension
    return null;
  }

  @override
  int getHeight() {
    // TODO: implement getHeight
    return null;
  }

  @override
  int getWidth() {
    // TODO: implement getWidth
    return null;
  }

  @override
  bool isAntiAlias() {
    // TODO: implement isAntiAlias
    return null;
  }

  @override
  bool isFilterBitmap() {
    // TODO: implement isFilterBitmap
    return null;
  }

  @override
  void resetClip() {
    // TODO: implement resetClip
  }

  @override
  void setAntiAlias(bool aa) {
    // TODO: implement setAntiAlias
  }

  @override
  void setBitmap(Bitmap bitmap) {
    // TODO: implement setBitmap
  }

  @override
  void setClip(int left, int top, int width, int height) {
    // TODO: implement setClip
  }

  @override
  void setClipDifference(int left, int top, int width, int height) {
    // TODO: implement setClipDifference
  }

  @override
  void setFilterBitmap(bool filter) {
    // TODO: implement setFilterBitmap
  }

  @override
  void shadeBitmap(Bitmap bitmap, Rectangle shadeRect, Rectangle tileRect,
      double magnitude) {
    // TODO: implement shadeBitmap
  }
}
