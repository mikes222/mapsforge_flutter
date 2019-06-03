import 'dart:ui' as ui;

import 'package:mapsforge_flutter/graphics/align.dart';
import 'package:mapsforge_flutter/graphics/bitmap.dart';
import 'package:mapsforge_flutter/graphics/cap.dart';
import 'package:mapsforge_flutter/graphics/color.dart';
import 'package:mapsforge_flutter/graphics/fontfamily.dart';
import 'package:mapsforge_flutter/graphics/fontstyle.dart';
import 'package:mapsforge_flutter/graphics/join.dart';
import 'package:mapsforge_flutter/graphics/mappaint.dart';
import 'package:mapsforge_flutter/graphics/style.dart';
import 'package:mapsforge_flutter/model/mappoint.dart';

import 'fluttercolor.dart';

class FlutterPaint extends ui.Paint implements MapPaint {
  final ui.Paint paint;

  FlutterPaint(this.paint);

  @override
  int getColor() {
    return paint.color.value;
  }

  @override
  double getStrokeWidth() {
    return paint.strokeWidth;
  }

  @override
  int getTextHeight(String text) {
    // TODO: implement getTextHeight
    return null;
  }

  @override
  int getTextWidth(String text) {
    // TODO: implement getTextWidth
    return null;
  }

  @override
  bool isTransparent() {
    // TODO: implement isTransparent
    return null;
  }

  @override
  void setBitmapShader(Bitmap bitmap) {
    // TODO: implement setBitmapShader
  }

  @override
  void setBitmapShaderShift(Mappoint origin) {
    // TODO: implement setBitmapShaderShift
  }

  @override
  void setColor(Color color) {
    paint.color = ui.Color(FlutterColor.getColor(color));
  }

  @override
  void setColorFromNumber(int color) {
    paint.color = ui.Color(color);
  }

  @override
  void setDashPathEffect(List<double> strokeDasharray) {
    // TODO: implement setDashPathEffect
  }

  @override
  void setStrokeCap(Cap cap) {
    // TODO: implement setStrokeCap
  }

  @override
  void setStrokeJoin(Join join) {
    // TODO: implement setStrokeJoin
  }

  @override
  void setStrokeWidth(double strokeWidth) {
    paint.strokeWidth = strokeWidth;
  }

  @override
  void setStyle(Style style) {
    // TODO: implement setStyle
  }

  @override
  void setTextAlign(Align align) {
    // TODO: implement setTextAlign
  }

  @override
  void setTextSize(double textSize) {
    // TODO: implement setTextSize
  }

  @override
  void setTypeface(FontFamily fontFamily, FontStyle fontStyle) {
    // TODO: implement setTypeface
  }
}
