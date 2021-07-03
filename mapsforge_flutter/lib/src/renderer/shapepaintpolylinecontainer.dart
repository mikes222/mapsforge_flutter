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

import '../graphics/mappaint.dart';
import '../renderer/shapecontainer.dart';

class ShapePaintPolylineContainer extends ShapePaintContainer {
  late MapPath path;

  static int count = 0;

  ShapePaintPolylineContainer(GraphicFactory graphicFactory, ShapeContainer shapeContainer, MapPaint paint, double dy)
      : super(shapeContainer, paint, dy) {
    path = graphicFactory.createPath();
  }

  @override
  void draw(MapCanvas canvas, PixelProjection projection) {
    ++count;
    PolylineContainer polylineContainer = shapeContainer as PolylineContainer;
    this.path.clear();

    for (List<Mappoint> outerList in polylineContainer.getCoordinatesRelativeToOrigin(projection)) {
      List<Mappoint> points;
      if (dy != 0) {
        points = RendererUtils.parallelPath(outerList, dy);
      } else {
        points = outerList;
      }
      MinMaxMappoint minMaxMappoint = MinMaxMappoint(points);
      if (minMaxMappoint.maxX < -3) {
        //print(minMaxMappoint);
        continue;
      }
      if (minMaxMappoint.maxY < -3) {
        //print(minMaxMappoint);
        continue;
      }
      if (minMaxMappoint.minX > (canvas as FlutterCanvas).size.width + 3) {
        //  print(minMaxMappoint);
        continue;
      }
      if (minMaxMappoint.minY > (canvas).size.height + 3) {
        //   print(minMaxMappoint);
        continue;
      }
      if (minMaxMappoint.maxX - minMaxMappoint.minX < 3 && minMaxMappoint.maxY - minMaxMappoint.minY < 3) {
        //   print(minMaxMappoint);
        continue;
      }
      //print("Drawing ShapePaintPolyline $minMaxMappoint with $paint");
      Mappoint point = points[0];
      this.path.moveTo(point.x, point.y);
      for (int i = 1; i < points.length; i++) {
        point = points[i];
        this.path.lineTo(point.x, point.y);
      }
    }

    canvas.drawPath(this.path, paint);
  }

  @override
  String toString() {
    return 'ShapePaintPolylineContainer{path: $path}';
  }
}
