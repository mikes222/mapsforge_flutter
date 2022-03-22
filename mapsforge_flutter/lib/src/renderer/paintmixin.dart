import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';

class PaintMixin {
  late MapPaint stroke;

  final Map<int, MapPaint> strokes = {};

  late MapPaint fill;

  final Map<int, MapPaint> fills = {};

  List<double>? strokeDasharray;

  void initPaintMixin() {
    this.stroke = GraphicFactory().createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);
    this.stroke.setStrokeWidth(1);
    this.stroke.setTextSize(10);
    this.stroke.setStrokeCap(Cap.ROUND);
    this.stroke.setStrokeJoin(Join.ROUND);

    this.fill = GraphicFactory().createPaint();
    this.fill.setColor(Color.BLACK);
    this.fill.setStyle(Style.FILL);
    this.fill.setStrokeCap(Cap.ROUND);
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = strokes[zoomLevel];
    paint ??= this.stroke;
    return paint;
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint? paint = fills[zoomLevel];
    paint ??= this.fill;
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
    if (this.strokes[zoomLevel] != null) return;
    MapPaint paint = GraphicFactory().createPaintFrom(this.stroke);
    paint.setStrokeWidth(paint.getStrokeWidth() * scaleFactor);
    if (strokeDasharray != null) {
      List<double> strokeDasharrayScaled = this.strokeDasharray!.map((dash) {
        return dash * scaleFactor;
      }).toList();
      paint.setStrokeDasharray(strokeDasharrayScaled);
    }
    this.strokes[zoomLevel] = paint;

    MapPaint f = GraphicFactory().createPaintFrom(this.fill);
    this.fills[zoomLevel] = f;
  }

  void mixinDispose() {
    strokes.values.forEach((element) {
      element.dispose();
    });
    stroke.dispose();
    fills.values.forEach((element) {
      element.dispose();
    });
    fill.dispose();
  }
}
