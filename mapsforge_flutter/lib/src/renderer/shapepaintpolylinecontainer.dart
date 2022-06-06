import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/minmaxmappoint.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/rendererutils.dart';
import 'package:mapsforge_flutter/src/renderer/shapepaintcontainer.dart';

import '../renderer/shapecontainer.dart';

class ShapePaintPolylineContainer extends ShapePaintContainer {
  late MapPath path;

  static int count = 0;

  final MapPaint? fill;

  final MapPaint? stroke;

  ShapePaintPolylineContainer(
      ShapeContainer shapeContainer, this.fill, this.stroke, double dy)
      : super(shapeContainer, dy) {
    path = GraphicFactory().createPath();
  }

  @override
  void draw(MapCanvas canvas, PixelProjection projection) {
    ++count;
    PolylineContainer polylineContainer = shapeContainer as PolylineContainer;
    this.path.clear();

    for (List<Mappoint> outerList
        in polylineContainer.getCoordinatesRelativeToOrigin(projection)) {
      List<Mappoint> points;
      if (dy != 0) {
        points = RendererUtils.parallelPath(outerList, dy);
      } else {
        points = outerList;
      }
      //print("Drawing ShapePaintPolyline $minMaxMappoint with $paint");
      Mappoint point = points[0];
      this.path.moveTo(point.x, point.y);
      //print("path moveTo $point");
      for (int i = 1; i < points.length; i++) {
        point = points[i];
        this.path.lineTo(point.x, point.y);
        //print("path lineTo $point");
      }
    }

    if (fill != null) canvas.drawPath(this.path, fill!);
    if (stroke != null) canvas.drawPath(this.path, stroke!);
  }

  @override
  String toString() {
    return 'ShapePaintPolylineContainer{path: $path}';
  }
}
