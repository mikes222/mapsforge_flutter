import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/relative_mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';
import '../graphics/implementation/fluttercanvas.dart';
import '../graphics/matrix.dart';
import '../graphics/resourcebitmap.dart';
import '../model/maprectangle.dart';
//import 'dart:ui' as ui;

class ShapePaintSymbol extends ShapePaint<ShapeSymbol> {
  final bool debug = false;

  late final MapPaint fill;

  ResourceBitmap? bitmap;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintSymbol._(ShapeSymbol shape) : super(shape) {
    fill = createPaint(style: Style.FILL);
  }

  static Future<ShapePaintSymbol> create(ShapeSymbol shape, SymbolCache symbolCache) async {
    return _taskQueue.add(() async {
      if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintSymbol;
      ShapePaintSymbol shapePaint = ShapePaintSymbol._(shape);
      await shapePaint.init(symbolCache);
      shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    bitmap =
        await createBitmap(symbolCache: symbolCache, bitmapSrc: shape.bitmapSrc!, bitmapWidth: shape.getBitmapWidth(), bitmapHeight: shape.getBitmapHeight());
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {
    if (bitmap == null) return;
    //print("paint symbol: $shape ${shape.bitmapSrc}");
    RelativeMappoint relative = coordinatesAbsolute.offset(-reference.x, -reference.y);
    MapRectangle boundary = shape.calculateBoundary();
    //print("paint symbol boundar: $boundary");
    Matrix? matrix;
    if (shape.theta != 0 || rotationRadian != 0) {
      matrix = GraphicFactory().createMatrix();
      // rotation of the rotationRadian parameter is always in the opposite direction.
      // If the map is moving clockwise we must rotate the symbol counterclockwise
      // to keep it horizontal
      matrix.rotate(shape.theta /*+ 2 * pi*/ - rotationRadian, pivotX: boundary.left, pivotY: boundary.top);
//        matrix.rotate(shapeSymbol.theta);
    }

    if (debug) {
      print(
          "drawing ${bitmap} ${fill.getColorAsNumber().toRadixString(16)} at ${relative.x + boundary.left} / ${relative.y + boundary.top} (${boundary.getWidth()},${boundary.getHeight()}) ${shape.theta}/$rotationRadian at size ${(canvas as FlutterCanvas).size}"); //bitmap.debugGetOpenHandleStackTraces();
      ui.Canvas? uiCanvas = (canvas).uiCanvas;
      uiCanvas.drawRect(ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top, boundary.getWidth(), boundary.getHeight()),
          ui.Paint()..color = Colors.red.withOpacity(0.5));
      uiCanvas.drawCircle(ui.Offset(relative.x, relative.y), 10, ui.Paint()..color = Colors.green.withOpacity(0.5));
    }

    canvas.drawBitmap(bitmap: bitmap!, matrix: matrix, left: relative.x + boundary.left, top: relative.y + boundary.top, paint: fill);
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    if (bitmap == null) return;
    Mappoint point = wayProperties.getCenterAbsolute(projection);
    RelativeMappoint relative = point.offset(-reference.x, -reference.y);
    MapRectangle boundary = shape.calculateBoundary();
    Matrix? matrix;
    if (shape.theta != 0) {
      matrix = GraphicFactory().createMatrix();
      matrix.rotate(shape.theta, pivotX: boundary.left, pivotY: boundary.top);
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    canvas.drawBitmap(bitmap: bitmap!, matrix: matrix, left: relative.x + boundary.left, top: relative.y + boundary.top, paint: fill);
  }
}
