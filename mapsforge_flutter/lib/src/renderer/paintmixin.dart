import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';

class PaintMixin {
  late MapPaint _stroke;

  final Map<int, MapPaint> _strokes = {};

  late MapPaint _fill;

  final Map<int, MapPaint> _fills = {};

  List<double>? _strokeDasharray;

  late double _dy = 0;

  final Map<int, double> _dyScaled = {};

  static final double STROKE_INCREASE = 1.5;

  /// stroke will be drawn thicker at or above this zoomlevel
  late int _strokeMinZoomLevel;

  void initPaintMixin(int strokeMinZoomLevel) {
    this._strokeMinZoomLevel = strokeMinZoomLevel;
    this._stroke = GraphicFactory().createPaint();
    this._stroke.setColor(Colors.black);
    this._stroke.setStyle(Style.STROKE);
    this._stroke.setStrokeWidth(1);
    this._stroke.setStrokeCap(Cap.ROUND);
    this._stroke.setStrokeJoin(Join.ROUND);

    this._fill = GraphicFactory().createPaint();
    this._fill.setColor(Colors.black);
    this._fill.setStyle(Style.FILL);
    this._fill.setStrokeCap(Cap.ROUND);
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = _strokes[zoomLevel];
    paint ??= this._stroke;
    return paint;
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint? paint = _fills[zoomLevel];
    paint ??= this._fill;
    return paint;
  }

  void prepareScalePaintMixin(int zoomLevel) {
    if (this._strokes[zoomLevel] != null) return;
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor = pow(STROKE_INCREASE, zoomLevelDiff) as double;
      MapPaint paint = GraphicFactory().createPaintFrom(this._stroke);
      paint.setStrokeWidth(paint.getStrokeWidth() * scaleFactor);
      // print(
      //     "setScrokeWitha for ${paint.getStrokeWidth()} $scaleFactor $zoomLevelDiff $zoomLevel ${_stroke.getStrokeWidth()}");
      if (_strokeDasharray != null) {
        List<double> strokeDasharrayScaled = this._strokeDasharray!.map((dash) {
          return dash * scaleFactor;
        }).toList();
        paint.setStrokeDasharray(strokeDasharrayScaled);
      }
      this._strokes[zoomLevel] = paint;

      //MapPaint f = GraphicFactory().createPaintFrom(this._fill);
      this._fills[zoomLevel] = _fill;

      double dy = _dy * scaleFactor;
      _dyScaled[zoomLevel] = dy;
    } else {
      this._strokes[zoomLevel] = _stroke;
      _fills[zoomLevel] = _fill;
      _dyScaled[zoomLevel] = _dy;
    }
  }

  void disposePaintMixin() {
    _strokes.values.forEach((element) {
      element.dispose();
    });
    _stroke.dispose();
    _fills.values.forEach((element) {
      element.dispose();
    });
    _fill.dispose();
  }

  void setFillColor(Color color) {
    _fill.setColor(color);
    _fills.forEach((key, value) {
      value.setColor(color);
    });
  }

  void setStrokeColor(Color color) {
    _stroke.setColor(color);
    _strokes.forEach((key, value) {
      value.setColor(color);
    });
  }

  void setFillColorFromNumber(int color) {
    _fill.setColorFromNumber(color);
    _fills.forEach((key, value) {
      value.setColorFromNumber(color);
    });
  }

  void setStrokeColorFromNumber(int color) {
    _stroke.setColorFromNumber(color);
    _strokes.forEach((key, value) {
      value.setColorFromNumber(color);
    });
  }

  bool isFillTransparent() {
    return _fill.isTransparent();
  }

  bool isStrokeTransparent() {
    return _stroke.isTransparent();
  }

  void setStrokeWidth(double strokeWidth) {
    _stroke.setStrokeWidth(strokeWidth);
    _strokes.clear();
    // _strokes.forEach((key, value) {
    //   value.setStrokeWidth(strokeWidth);
    // });
  }

  double getStrokeWidth() {
    return _stroke.getStrokeWidth();
  }

  void setFillBitmapShader(Bitmap bitmap) {
    // make sure the color is not transparent
    if (isFillTransparent()) setFillColor(Colors.black);
    _fill.setBitmapShader(bitmap);
    _fills.forEach((key, value) {
      // make sure the color is not transparent
      if (value.isTransparent()) value.setColor(Colors.black);
      value.setBitmapShader(bitmap);
    });
  }

  void setStrokeBitmapShader(Bitmap bitmap) {
    // make sure the color is not transparent
    if (isStrokeTransparent()) setStrokeColor(Colors.black);
    _stroke.setBitmapShader(bitmap);
    _strokes.forEach((key, value) {
      // make sure the color is not transparent
      if (value.isTransparent()) value.setColor(Colors.black);
      value.setBitmapShader(bitmap);
    });
    //strokePaint.setBitmapShaderShift(way.getUpperLeft().getOrigin());
    //bitmap.incrementRefCount();
  }

  void setStrokeJoin(Join join) {
    _stroke.setStrokeJoin(join);
    _strokes.forEach((key, value) {
      value.setStrokeJoin(join);
    });
  }

  void setStrokeCap(Cap cap) {
    _stroke.setStrokeCap(cap);
    _strokes.forEach((key, value) {
      value.setStrokeCap(cap);
    });
  }

  void setStrokeDashArray(List<double> dashArray) {
    _strokeDasharray = dashArray;
    // expanding by scaleFactor looks too large. Shortening strokes
    List<double> strokeDasharrayScaled = this._strokeDasharray!.map((dash) {
      return dash / 4;
    }).toList();
    _strokeDasharray = strokeDasharrayScaled;
    _stroke.setStrokeDasharray(dashArray);
    _strokes.forEach((key, value) {
      value.setStrokeDasharray(dashArray);
    });
  }

  void setDy(double dy) {
    _dy = dy;
    _dyScaled.clear();
  }

  double getDy(int zoomLevel) {
    if (_dyScaled[zoomLevel] != null) return _dyScaled[zoomLevel]!;
    return _dy;
  }

  void clearPaintMixin() {
    _dyScaled.clear();
    _strokes.clear();
    _fills.clear();
  }
}
