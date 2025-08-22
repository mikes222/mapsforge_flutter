import 'dart:ui' as ui;

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_matrix.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintSymbol extends UiShapePainter<RenderinstructionSymbol> {
  static final _log = Logger('ShapePaintSymbol');

  final bool debug = false;

  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintSymbol._(RenderinstructionSymbol renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill();
  }

  static Future<ShapePaintSymbol> create(RenderinstructionSymbol renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintSymbol;
      ShapePaintSymbol shapePaint = ShapePaintSymbol._(renderinstruction);
      await shapePaint.init();
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  Future<void> init() async {
    try {
      symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
        renderinstruction.bitmapSrc!,
        renderinstruction.getBitmapWidth(),
        renderinstruction.getBitmapHeight(),
      );
    } catch (error) {
      _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
    }
  }

  void dispose() {
    symbolImage?.dispose();
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (symbolImage == null) return;
    //print("paint symbol: $shape ${shape.bitmapSrc}");
    RelativeMappoint relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    MapRectangle boundary = renderinstruction.getBoundary()!;
    //print("paint symbol boundar: $boundary");
    UiMatrix? matrix;
    if (renderinstruction.theta != 0 || renderContext.rotationRadian != 0) {
      matrix = UiMatrix();
      // rotation of the rotationRadian parameter is always in the opposite direction.
      // If the map is moving clockwise we must rotate the symbol counterclockwise
      // to keep it horizontal
      matrix.rotate(renderinstruction.theta /*+ 2 * pi*/ - renderContext.rotationRadian, pivotX: boundary.left, pivotY: boundary.top);
      //        matrix.rotate(shapeSymbol.theta);
    }

    if (debug) {
      // print(
      //   "drawing ${symbolImage} ${fill.getColorAsNumber().toRadixString(16)} at ${relative.x + boundary.left} / ${relative.y + boundary.top} (${boundary.getWidth()},${boundary.getHeight()}) ${renderinstruction.theta}/$rotationRadian at size ${(canvas as FlutterCanvas).size}",
      // ); //bitmap.debugGetOpenHandleStackTraces();
      ui.Canvas? uiCanvas = renderContext.canvas.expose();
      uiCanvas.drawRect(
        ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top, boundary.getWidth(), boundary.getHeight()),
        ui.Paint()..color = Colors.red.withOpacity(0.5),
      );
      uiCanvas.drawCircle(ui.Offset(relative.x, relative.y), 10, ui.Paint()..color = Colors.green.withOpacity(0.5));
    }

    renderContext.canvas.drawPicture(symbolImage: symbolImage!, matrix: matrix, left: relative.x + boundary.left, top: relative.y + boundary.top, paint: fill);
  }

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (symbolImage == null) return;
    Mappoint point = wayProperties.getCenterAbsolute(renderContext.projection);
    RelativeMappoint relative = point.offset(renderContext.reference);
    MapRectangle boundary = renderinstruction.getBoundary()!;
    UiMatrix? matrix;
    if (renderinstruction.theta != 0) {
      matrix = UiMatrix();
      matrix.rotate(renderinstruction.theta, pivotX: boundary.left, pivotY: boundary.top);
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    renderContext.canvas.drawPicture(symbolImage: symbolImage!, matrix: matrix, left: relative.x + boundary.left, top: relative.y + boundary.top, paint: fill);
  }

  @override
  MapRectangle getBoundary() {
    return renderinstruction.getBoundary()!;
  }
}
