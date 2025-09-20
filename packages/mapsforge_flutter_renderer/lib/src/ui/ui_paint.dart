import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

/// A wrapper around Flutter's `ui.Paint` to simplify paint configuration for
/// map rendering.
///
/// This class provides convenient constructors for creating stroke and fill paints,
/// and methods for setting properties like color, stroke width, and shaders.
/// It also handles the disposal of associated resources, such as bitmap shaders.
class UiPaint {
  final ui.Paint _paint;

  SymbolImage? _shaderBitmap;

  List<double>? _strokeDasharray;

  /// Creates a new paint object for stroking paths.
  UiPaint.stroke({int? color, double? strokeWidth, MapCap? cap, MapJoin? join, List<double>? strokeDasharray})
    : _paint = ui.Paint()..style = ui.PaintingStyle.stroke {
    if (color != null) _paint.color = Color(color);
    if (strokeWidth != null) _paint.strokeWidth = strokeWidth;
    if (cap != null) setStrokeCap(cap);
    if (join != null) setStrokeJoin(join);
    if (strokeDasharray != null) _strokeDasharray = strokeDasharray;
  }

  /// Creates a new paint object for filling paths.
  UiPaint.fill({int? color}) : _paint = ui.Paint()..style = ui.PaintingStyle.fill {
    if (color != null) _paint.color = Color(color);
  }

  /// Creates a new paint object as a copy of another `UiPaint`.
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

  /// Disposes the bitmap shader associated with this paint, if any.
  void dispose() {
    _shaderBitmap?.dispose();
  }

  /// Returns the color of this paint as a 32-bit integer.
  int getColorAsNumber() {
    return _paint.color.value;
  }

  /// Returns the color of this paint as a `ui.Color`.
  ui.Color getColor() => _paint.color;

  /// Returns the stroke width of this paint.
  double getStrokeWidth() {
    return _paint.strokeWidth;
  }

  /// Sets the color of this paint from a `ui.Color`.
  void setColor(ui.Color color) {
    _paint.color = color;
  }

  /// Sets the color of this paint from a 32-bit integer.
  void setColorFromNumber(int color) {
    _paint.color = ui.Color(color);
  }

  /// Sets the stroke cap style for this paint.
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

  /// Sets the stroke join style for this paint.
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

  /// Sets the stroke width for this paint.
  void setStrokeWidth(double strokeWidth) {
    _paint.strokeWidth = strokeWidth;
  }

  /// Sets the shader for this paint to a bitmap pattern.
  ///
  /// The given [symbolImage] will not be disposed by this method.
  void setBitmapShader(SymbolImage symbolImage) {
    _shaderBitmap = symbolImage;
    _paint.shader = symbolImage.getShader();
  }

  /// Returns the bitmap shader for this paint, if any.
  SymbolImage? getBitmapShader() {
    return _shaderBitmap;
  }

  /// Returns true if the color of this paint is transparent.
  bool isTransparent() {
    return _paint.color == mat.Colors.transparent;
    //return paint.color == ui.Color(FlutterColor.getColor(Color.TRANSPARENT));
  }

  /// Sets whether to apply anti-aliasing when drawing with this paint.
  void setAntiAlias(bool value) {
    _paint.isAntiAlias = value;
  }

  /// Returns true if anti-aliasing is enabled for this paint.
  bool getAntiAlias() {
    return _paint.isAntiAlias;
  }

  /// Sets the stroke dash array for this paint.
  void setStrokeDasharray(List<double>? strokeDasharray) {
    _strokeDasharray = strokeDasharray;
  }

  /// Returns the stroke dash array for this paint, if any.
  List<double>? getStrokeDasharray() {
    return _strokeDasharray;
  }

  /// Exposes the underlying `ui.Paint` object for direct use.
  ui.Paint expose() => _paint;

  /// Returns true if this paint is a fill paint.
  bool isFillPaint() => _paint.style == PaintingStyle.fill;
}
