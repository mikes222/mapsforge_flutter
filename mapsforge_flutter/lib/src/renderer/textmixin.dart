import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';

class TextMixin {
  MapPaint? stroke;

  final Map<int, MapPaint> strokes = {};

  MapPaint? fill;

  final Map<int, MapPaint> fills = {};

  double _fontSize = 10;

  void initTextMixin(GraphicFactory graphicFactory) {
    this.stroke = graphicFactory.createPaint();
    this.stroke!.setColor(Color.BLACK);
    this.stroke!.setStyle(Style.STROKE);
    this.stroke!.setStrokeWidth(1);
    this.stroke!.setTextSize(10);

    this.fill = graphicFactory.createPaint();
    this.fill!.setColor(Color.BLACK);
    this.fill!.setStyle(Style.FILL);
  }

  void initMixinAfterParse(MapFontFamily fontFamily, MapFontStyle fontStyle) {
    this.fill?.setTypeface(fontFamily, fontStyle);
    this.stroke?.setTypeface(fontFamily, fontStyle);
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = strokes[zoomLevel];
    paint ??= this.stroke;
    // if this property is null you forgot to call initTextMixin() first
    return paint!;
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint? paint = fills[zoomLevel];
    paint ??= this.fill;
    // if this property is null you forgot to call initTextMixin() first
    return paint!;
  }

  void scaleMixinStrokeWidth(
      GraphicFactory graphicFactory, double scaleFactor, int zoomLevel) {
    //if (this.strokes[zoomLevel] != null) return;
    // we setup the stroke-params for the desired zoomlevel together with the fontsize for this zoomlevel
    scaleMixinTextSize(graphicFactory, scaleFactor, zoomLevel);
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

  void scaleMixinTextSize(
      GraphicFactory graphicFactory, double scaleFactor, int zoomLevel) {
    final int zoom = 19;
    if (this.strokes[zoomLevel] != null) return;
    if (zoomLevel >= zoom) {
      MapPaint paint = graphicFactory.createPaintFrom(this.stroke!);
      paint.setStrokeWidth(paint.getStrokeWidth() * (zoomLevel - zoom + 2));
      paint.setTextSize(this._fontSize * (zoomLevel - zoom + 2));
      this.strokes[zoomLevel] = paint;
    } else {
      MapPaint paint = graphicFactory.createPaintFrom(this.stroke!);
      paint.setTextSize(this._fontSize);
      this.strokes[zoomLevel] = paint;
    }

    if (zoomLevel >= zoom) {
      MapPaint f = graphicFactory.createPaintFrom(this.fill!);
      f.setTextSize(this._fontSize * (zoomLevel - zoom + 2));
      this.fills[zoomLevel] = f;
    } else {
      MapPaint f = graphicFactory.createPaintFrom(this.fill!);
      f.setTextSize(this._fontSize);
      this.fills[zoomLevel] = f;
    }
  }

  void set fontSize(double value) {
    _fontSize = value;
    stroke!.setTextSize(value);
    fill!.setTextSize(value);
  }

  void mixinDispose() {
    strokes.values.forEach((element) {
      element.dispose();
    });
    stroke?.dispose();
    fills.values.forEach((element) {
      element.dispose();
    });
    fill?.dispose();
  }
}
