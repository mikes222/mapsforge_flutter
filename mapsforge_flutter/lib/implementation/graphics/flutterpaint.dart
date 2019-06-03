import 'dart:typed_data';
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

import 'flutterbitmap.dart';
import 'fluttercolor.dart';

class FlutterPaint extends ui.Paint implements MapPaint {
  final ui.Paint paint;

  FlutterBitmap _shaderBitmap;

  FlutterPaint(this.paint);

  FlutterPaint.from(FlutterPaint other) : paint = other.paint {
    paint.color = other.paint.color;
    paint.strokeWidth = other.paint.strokeWidth;
    paint.style = other.paint.style;
    paint.strokeJoin = other.paint.strokeJoin;
    paint.strokeCap = other.paint.strokeCap;
    if (other._shaderBitmap != null) {
      _shaderBitmap = other._shaderBitmap;
      _shaderBitmap.incrementRefCount();
      paint.shader = other.paint.shader;
    }
  }

  @override
  int getColor() {
    return paint.color.value;
  }

  @override
  double getStrokeWidth() {
    return paint.strokeWidth;
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
  void setStrokeCap(Cap cap) {
    switch (cap) {
      case Cap.BUTT:
        paint.strokeCap = ui.StrokeCap.butt;
        break;
      case Cap.ROUND:
        paint.strokeCap = ui.StrokeCap.round;
        break;
      case Cap.SQUARE:
        paint.strokeCap = ui.StrokeCap.square;
        break;
    }
  }

  @override
  void setStrokeJoin(Join join) {
    switch (join) {
      case Join.BEVEL:
        paint.strokeJoin = ui.StrokeJoin.bevel;
        break;
      case Join.MITER:
        paint.strokeJoin = ui.StrokeJoin.miter;
        break;
      case Join.ROUND:
        paint.strokeJoin = ui.StrokeJoin.round;
        break;
    }
  }

  @override
  void setStrokeWidth(double strokeWidth) {
    paint.strokeWidth = strokeWidth;
  }

  @override
  void setStyle(Style style) {
    switch (style) {
      case Style.FILL:
        paint.style = ui.PaintingStyle.fill;
        break;
      case Style.STROKE:
        paint.style = ui.PaintingStyle.stroke;
        break;
    }
  }

  @override
  void setBitmapShader(Bitmap bitmap) {
    if (_shaderBitmap != null) _shaderBitmap.decrementRefCount();
    _shaderBitmap = bitmap;
    bitmap.incrementRefCount();
    ui.Image img = _shaderBitmap.bitmap;
    paint.shader = ui.ImageShader(img, ui.TileMode.repeated, ui.TileMode.repeated, Float64List(0));
  }

  @override
  bool isTransparent() {
    // TODO: implement isTransparent
    return null;
  }

  @override
  void setBitmapShaderShift(Mappoint origin) {
    // TODO: implement setBitmapShaderShift
  }

  @override
  void setDashPathEffect(List<double> strokeDasharray) {
    // TODO: implement setDashPathEffect
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
}
