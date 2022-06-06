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

  void initPaintMixin() {
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

  void scaleMixinStrokeWidth(double scaleFactor, int zoomLevel) {
    //if (this.strokes[zoomLevel] != null) return;
    // we setup the stroke-params for the desired zoomlevel together with the fontsize for this zoomlevel
    scaleMixinTextSize(scaleFactor, zoomLevel);
    // MapPaint paint = graphicFactory.createPaintFrom(this.stroke);
    // paint.setStrokeWidth(paint.getStrokeWidth() * scaleFactor);
    // if (strokeDasharray != null) {
    //   // List<double> strokeDasharrayScaled = this.strokeDasharray!.map((dash) {
    //   //   return dash * scaleFactor;
    //   // }).toList();
    //   paint.setStrokeDasharray(strokeDasharray);
    // }
    // this.strokes[zoomLevel] = paint;
  }

  void scaleMixinTextSize(double scaleFactor, int zoomLevel) {
    if (this._strokes[zoomLevel] != null) return;
    MapPaint paint = GraphicFactory().createPaintFrom(this._stroke);
    paint.setStrokeWidth(paint.getStrokeWidth() * scaleFactor);
    if (_strokeDasharray != null) {
      List<double> strokeDasharrayScaled = this._strokeDasharray!.map((dash) {
        return dash * scaleFactor;
      }).toList();
      paint.setStrokeDasharray(strokeDasharrayScaled);
    }
    this._strokes[zoomLevel] = paint;

    MapPaint f = GraphicFactory().createPaintFrom(this._fill);
    this._fills[zoomLevel] = f;
  }

  void mixinDispose() {
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
    _strokes.forEach((key, value) {
      value.setStrokeWidth(strokeWidth);
    });
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
}
