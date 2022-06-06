import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertextpaint.dart';

class TextMixin {
  late MapPaint _stroke;

  final Map<int, MapPaint> _strokes = {};

  late MapPaint _fill;

  final Map<int, MapPaint> _fills = {};

  late MapTextPaint _textPaint;

  final Map<int, MapTextPaint> _textPaints = {};

  void initTextMixin() {
    this._stroke = GraphicFactory().createPaint();
    this._stroke.setColor(Colors.black);
    this._stroke.setStyle(Style.STROKE);
    this._stroke.setStrokeWidth(1);

    _textPaint = GraphicFactory().createTextPaint();
    this._textPaint.setTextSize(10);

    this._fill = GraphicFactory().createPaint();
    this._fill.setColor(Colors.black);
    this._fill.setStyle(Style.FILL);
  }

  void setFontFamily(MapFontFamily fontFamily) {
    _textPaint.setFontFamily(fontFamily);
  }

  void setFontStyle(MapFontStyle fontStyle) {
    _textPaint.setFontStyle(fontStyle);
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = _strokes[zoomLevel];
    paint ??= this._stroke;
    // if this property is null you forgot to call initTextMixin() first
    return paint;
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint? paint = _fills[zoomLevel];
    paint ??= this._fill;
    // if this property is null you forgot to call initTextMixin() first
    return paint;
  }

  MapTextPaint getTextPaint(int zoomLevel) {
    MapTextPaint? paint = _textPaints[zoomLevel];
    paint ??= _textPaint;
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
    final int zoom = 19;
    if (this._strokes[zoomLevel] != null) return;
    if (zoomLevel >= zoom) {
      MapPaint paint = GraphicFactory().createPaintFrom(this._stroke);
      paint.setStrokeWidth(paint.getStrokeWidth() * (zoomLevel - zoom + 2));
      this._strokes[zoomLevel] = paint;

      MapPaint f = GraphicFactory().createPaintFrom(this._fill);
      this._fills[zoomLevel] = f;

      MapTextPaint t = FlutterTextPaint.from(_textPaint);
      t.setTextSize(_textPaint.getTextSize() * (zoomLevel - zoom + 2));
      _textPaints[zoomLevel] = t;
    } else {
//      MapPaint paint = GraphicFactory().createPaintFrom(this._stroke!);
      this._strokes[zoomLevel] = _stroke;

//      MapPaint f = GraphicFactory().createPaintFrom(this._fill!);
      this._fills[zoomLevel] = _fill;

      _textPaints[zoomLevel] = _textPaint;
    }
  }

  void set fontSize(double value) {
    _textPaint.setTextSize(value);
    // next call of [scaleMixinTextSize] will refill these values
    _textPaints.clear();
    _strokes.clear();
    _fills.clear();
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
  }

  void setStrokeColor(Color color) {
    _stroke.setColor(color);
  }

  void setFillColorFromNumber(int color) {
    _fill.setColorFromNumber(color);
  }

  void setStrokeColorFromNumber(int color) {
    _stroke.setColorFromNumber(color);
  }

  bool isFillTransparent() {
    return _fill.isTransparent();
  }

  void setStrokeWidth(double strokeWidth) {
    _stroke.setStrokeWidth(strokeWidth);
  }
}
