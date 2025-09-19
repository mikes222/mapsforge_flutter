import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

class UiPaint {
  final ui.Paint _paint;

  SymbolImage? _shaderBitmap;

  List<double>? _strokeDasharray;

  UiPaint.stroke({int? color, double? strokeWidth, MapCap? cap, MapJoin? join, List<double>? strokeDasharray})
    : _paint = ui.Paint()..style = ui.PaintingStyle.stroke {
    if (color != null) _paint.color = Color(color);
    if (strokeWidth != null) _paint.strokeWidth = strokeWidth;
    if (cap != null) setStrokeCap(cap);
    if (join != null) setStrokeJoin(join);
    if (strokeDasharray != null) _strokeDasharray = strokeDasharray;
  }

  UiPaint.fill({int? color}) : _paint = ui.Paint()..style = ui.PaintingStyle.fill {
    if (color != null) _paint.color = Color(color);
  }

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

  void setStrokeCap(MapCap cap) {
    switch (cap) {
      case MapCap.BUTT:
        _paint.strokeCap = ui.StrokeCap.butt;
        break;
      case MapCap.ROUND:
        _paint.strokeCap = ui.StrokeCap.round;
        break;
      case MapCap.SQUARE:
        _paint.strokeCap = ui.StrokeCap.square;
        break;
    }
  }

  void setStrokeJoin(MapJoin join) {
    switch (join) {
      case MapJoin.BEVEL:
        _paint.strokeJoin = ui.StrokeJoin.bevel;
        break;
      case MapJoin.MITER:
        _paint.strokeJoin = ui.StrokeJoin.miter;
        break;
      case MapJoin.ROUND:
        _paint.strokeJoin = ui.StrokeJoin.round;
        break;
    }
  }

  void setStrokeWidth(double strokeWidth) {
    _paint.strokeWidth = strokeWidth;
  }

  /// Sets the shader for this paint. The given symbol will NOT be disposed
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

  void setStrokeDasharray(List<double>? strokeDasharray) {
    _strokeDasharray = strokeDasharray;
  }

  List<double>? getStrokeDasharray() {
    return _strokeDasharray;
  }

  ui.Paint expose() => _paint;

  bool isFillPaint() => _paint.style == PaintingStyle.fill;
}
