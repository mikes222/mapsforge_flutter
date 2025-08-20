import 'dart:ui' as ui;

import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;

class UiPaint {
  final ui.Paint _paint;

  SymbolImage? _shaderBitmap;

  List<double>? _strokeDasharray;

  UiPaint.stroke() : _paint = ui.Paint()..style = ui.PaintingStyle.stroke;

  UiPaint.fill() : _paint = ui.Paint()..style = ui.PaintingStyle.fill;

  UiPaint.from(UiPaint other) : _paint = ui.Paint() {
    _paint.color = other._paint.color;
    _paint.strokeWidth = other._paint.strokeWidth;
    _paint.style = other._paint.style;
    _paint.strokeJoin = other._paint.strokeJoin;
    _paint.strokeCap = other._paint.strokeCap;
    _strokeDasharray = other._strokeDasharray;
    if (other._shaderBitmap != null) {
      setBitmapShader(other._shaderBitmap!);
    }
  }

  void dispose() {
    _shaderBitmap?.dispose();
  }

  int getColorAsNumber() {
    return _paint.color.value;
  }

  ui.Color getColor() => _paint.color;

  double getStrokeWidth() {
    return _paint.strokeWidth;
  }

  void setColor(ui.Color color) {
    _paint.color = color;
  }

  void setColorFromNumber(int color) {
    _paint.color = ui.Color(color);
  }

  void setStrokeCap(Cap cap) {
    switch (cap) {
      case Cap.BUTT:
        _paint.strokeCap = ui.StrokeCap.butt;
        break;
      case Cap.ROUND:
        _paint.strokeCap = ui.StrokeCap.round;
        break;
      case Cap.SQUARE:
        _paint.strokeCap = ui.StrokeCap.square;
        break;
    }
  }

  void setStrokeJoin(Join join) {
    switch (join) {
      case Join.BEVEL:
        _paint.strokeJoin = ui.StrokeJoin.bevel;
        break;
      case Join.MITER:
        _paint.strokeJoin = ui.StrokeJoin.miter;
        break;
      case Join.ROUND:
        _paint.strokeJoin = ui.StrokeJoin.round;
        break;
    }
  }

  void setStrokeWidth(double strokeWidth) {
    _paint.strokeWidth = strokeWidth;
  }

  void setBitmapShader(SymbolImage symbolImage) {
    _shaderBitmap = symbolImage;
    _paint.shader = symbolImage.getShader();
  }

  SymbolImage? getBitmapShader() {
    return _shaderBitmap;
  }

  bool isTransparent() {
    return _paint.color == mat.Colors.transparent;
    //return paint.color == ui.Color(FlutterColor.getColor(Color.TRANSPARENT));
  }

  void setAntiAlias(bool value) {
    _paint.isAntiAlias = value;
  }

  bool getAntiAlias() {
    return _paint.isAntiAlias;
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

  void setStrokeDasharray(List<double>? strokeDasharray) {
    _strokeDasharray = strokeDasharray;
  }

  List<double>? getStrokeDasharray() {
    return _strokeDasharray;
  }

  ui.Paint expose() => _paint;

  bool isFillPaint() => _paint.style == PaintingStyle.fill;
}
