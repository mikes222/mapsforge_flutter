import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart' as mat;
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';

import 'flutterbitmap.dart';
import 'fluttercanvas.dart';
import 'fluttercolor.dart';

class FlutterPaint implements MapPaint {
  final ui.Paint paint;

  FlutterBitmap? _shaderBitmap;

  double _textSize = 10;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  List<double>? _strokeDasharray;

  FlutterPaint(this.paint);

  FlutterPaint.from(FlutterPaint other) : paint = ui.Paint() {
    paint.color = other.paint.color;
    paint.strokeWidth = other.paint.strokeWidth;
    paint.style = other.paint.style;
    paint.strokeJoin = other.paint.strokeJoin;
    paint.strokeCap = other.paint.strokeCap;
    _textSize = other._textSize;
    _fontStyle = other._fontStyle;
    _fontFamily = other._fontFamily;
    _strokeDasharray = other._strokeDasharray;
    if (other._shaderBitmap != null) {
      setBitmapShader(other._shaderBitmap!);
    }
  }

  @override
  void dispose() {
    _shaderBitmap?.decrementRefCount();
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
    if (_shaderBitmap != null) _shaderBitmap!.decrementRefCount();
    _shaderBitmap = bitmap as FlutterBitmap;
    _shaderBitmap!.incrementRefCount();
    ui.Image img = _shaderBitmap!.bitmap;

    // final double devicePixelRatio = ui.window.devicePixelRatio;
    // final Float64List deviceTransform = new Float64List(16)
    //   ..[0] = devicePixelRatio
    //   ..[5] = devicePixelRatio
    //   ..[10] = 1.0
    //   ..[15] = 2.0;
    Float64List deviceTransform =
        Float64List.fromList(mat.Matrix4.identity().storage);
    paint.shader = ui.ImageShader(
        img, ui.TileMode.repeated, ui.TileMode.repeated, deviceTransform);
  }

  @override
  Bitmap? getBitmapShader() {
    return _shaderBitmap;
  }

  @override
  bool isTransparent() {
    return paint.color == mat.Colors.transparent;
    //return paint.color == ui.Color(FlutterColor.getColor(Color.TRANSPARENT));
  }

  @override
  void setAntiAlias(bool value) {
    paint.isAntiAlias = value;
  }

  @override
  bool getAntiAlias() {
    return paint.isAntiAlias;
  }

  // @override
  // void setBitmapShaderShift(Mappoint origin) {
  //   // TODO: implement setBitmapShaderShift
  // }
  //
  // @override
  // void setTextAlign(Align align) {
  //   // TODO: implement setTextAlign
  // }

  @override
  void setTextSize(double textSize) {
    _textSize = textSize;
  }

  @override
  double getTextSize() {
    return _textSize;
  }

  @override
  void setTypeface(MapFontFamily fontFamily, MapFontStyle fontStyle) {
    _fontStyle = fontStyle;
    _fontFamily = fontFamily;
  }

  @override
  MapFontStyle getFontStyle() {
    return _fontStyle;
  }

  @override
  int getTextHeight(String text) {
    return _textSize.ceil();
  }

  @override
  int getTextWidth(String text) {
    return FlutterCanvas.calculateTextWidth(text, _textSize, this).ceil();
  }

  ui.ParagraphBuilder buildParagraphBuilder(String text) {
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: _textSize,
        //textAlign: TextAlign.center,
        fontStyle: getFontStyle() == MapFontStyle.BOLD_ITALIC ||
                getFontStyle() == MapFontStyle.ITALIC
            ? ui.FontStyle.italic
            : ui.FontStyle.normal,
        fontWeight: getFontStyle() == MapFontStyle.BOLD ||
                getFontStyle() == MapFontStyle.BOLD_ITALIC
            ? ui.FontWeight.bold
            : ui.FontWeight.normal,
        //fontFamily: _fontFamily == MapFontFamily.MONOSPACE ? FontFamily.MONOSPACE : FontFamily.DEFAULT,
      ),
    );

    if (getStrokeWidth() == 0)
      builder.pushStyle(ui.TextStyle(
        color: paint.color,
        fontFamily: _fontFamily.toString().replaceAll("MapFontFamily.", ""),
      ));
    else
      builder.pushStyle(ui.TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.strokeWidth
          ..color = paint.color,
        fontFamily: _fontFamily.toString().replaceAll("MapFontFamily.", ""),
      ));

    builder.addText(text);
    return builder;
  }

  @override
  void setStrokeDasharray(List<double>? strokeDasharray) {
    this._strokeDasharray = strokeDasharray;
  }

  @override
  List<double>? getStrokeDasharray() {
    return _strokeDasharray;
  }

  @override
  String toString() {
    return 'FlutterPaint{paint: $paint, color: ${paint.color}, _shaderBitmap: $_shaderBitmap, _textSize: $_textSize, _fontStyle: $_fontStyle, _fontFamily: $_fontFamily, _strokeDasharray: $_strokeDasharray}';
  }
}
