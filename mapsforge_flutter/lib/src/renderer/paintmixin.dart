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

  void initPaintMixin(GraphicFactory graphicFactory) {
    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);
    this.stroke.setStrokeWidth(1);
    this.stroke.setTextSize(10);
    this.stroke.setStrokeCap(Cap.ROUND);
    this.stroke.setStrokeJoin(Join.ROUND);

    this.fill = graphicFactory.createPaint();
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
    if (this.strokes[zoomLevel] != null) return;
    MapPaint paint = graphicFactory.createPaintFrom(this.stroke);
    paint.setStrokeWidth(paint.getStrokeWidth() * scaleFactor);
    if (strokeDasharray != null) {
      // List<double> strokeDasharrayScaled = this.strokeDasharray!.map((dash) {
      //   return dash * scaleFactor;
      // }).toList();
      paint.setStrokeDasharray(strokeDasharray);
    }
    this.strokes[zoomLevel] = paint;

    MapPaint f = graphicFactory.createPaintFrom(this.fill);
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
