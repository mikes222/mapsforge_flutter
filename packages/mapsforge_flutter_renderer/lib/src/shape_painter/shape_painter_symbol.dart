import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_matrix.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering bitmap symbols on the map.
///
/// This painter is responsible for drawing bitmap images (symbols) for POIs or
/// other map features. It handles loading the symbol from the cache, applying
/// color tinting, and managing rotation.
class ShapePainterSymbol extends UiShapePainter<RenderinstructionSymbol> {
  static final _log = Logger('ShapePainterSymbol');

  static const bool debug = false;

  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterSymbol");

  ShapePainterSymbol._(RenderinstructionSymbol renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill(color: renderinstruction.getBitmapColor());
  }

  /// Creates a new symbol shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterSymbol> create(RenderinstructionSymbol renderinstruction) async {
    return _taskQueue.add(() async {
      ShapePainterSymbol? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterSymbol?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterSymbol._(renderinstruction);
      await shapePainter.init();
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Initializes the shape painter by loading the symbol from the cache.
  Future<void> init() async {
    try {
      symbolImage =
          await SymbolCacheMgr().getOrCreateSymbol(renderinstruction.bitmapSrc!, renderinstruction.getBitmapWidth(), renderinstruction.getBitmapHeight())
            ?..clone();
    } catch (error) {
      _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
    }
  }

  @override
  /// Disposes the [symbolImage].
  @override
  void dispose() {
    symbolImage?.dispose();
    symbolImage = null;
  }

  /// Renders a symbol for a node (e.g., a POI).
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (symbolImage == null) return;
    MappointRelative relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    MapRectangle boundary = renderinstruction.getBoundary(renderInfo);
    UiMatrix? matrix;
    if (renderinstruction.rotateWithMap) {
      if (renderinstruction.theta != 0) {
        matrix = UiMatrix();
        // rotation of the rotationRadian parameter is always in the opposite direction.
        // If the map is moving clockwise we must rotate the symbol counterclockwise
        // to keep it horizontal
        matrix.rotate(renderinstruction.theta, pivotX: boundary.left, pivotY: boundary.top);
      }
    } else {
      if (renderinstruction.theta != 0 || renderContext.rotationRadian != 0) {
        matrix = UiMatrix();
        // rotation of the rotationRadian parameter is always in the opposite direction.
        // If the map is moving clockwise we must rotate the symbol counterclockwise
        // to keep it horizontal
        matrix.rotate(renderinstruction.theta - renderContext.rotationRadian, pivotX: boundary.left, pivotY: boundary.top);
      }
    }

    if (debug) {
      // print(
      //   "drawing ${symbolImage} ${fill.getColorAsNumber().toRadixString(16)} at ${relative.x + boundary.left} / ${relative.y + boundary.top} (${boundary.getWidth()},${boundary.getHeight()}) ${renderinstruction.theta}/$rotationRadian at size ${(canvas as FlutterCanvas).size}",
      // ); //bitmap.debugGetOpenHandleStackTraces();
      ui.Canvas? uiCanvas = renderContext.canvas.expose();
      uiCanvas.drawRect(
        ui.Rect.fromLTWH(relative.dx + boundary.left, relative.dy + boundary.top, boundary.getWidth(), boundary.getHeight()),
        ui.Paint()..color = Colors.red.withOpacity(0.5),
      );
      uiCanvas.drawCircle(ui.Offset(relative.dx, relative.dy), 10, ui.Paint()..color = Colors.green.withOpacity(0.5));
    }

    renderContext.canvas.drawPicture(
      symbolImage: symbolImage!,
      matrix: matrix,
      left: relative.dx + boundary.left,
      top: relative.dy + boundary.top,
      paint: fill,
    );
  }

  /// Renders a symbol for a way.
  ///
  /// The symbol is drawn at the center of the way's bounding box.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (symbolImage == null) return;
    Mappoint point = wayProperties.getCenterAbsolute(renderContext.projection);
    MappointRelative relative = point.offset(renderContext.reference);
    MapRectangle boundary = renderinstruction.getBoundary(renderInfo);
    UiMatrix? matrix;
    if (renderinstruction.theta != 0 || renderContext.rotationRadian != 0) {
      matrix = UiMatrix();
      matrix.rotate(renderinstruction.theta - renderContext.rotationRadian, pivotX: boundary.left, pivotY: boundary.top);
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    renderContext.canvas.drawPicture(
      symbolImage: symbolImage!,
      matrix: matrix,
      left: relative.dx + boundary.left,
      top: relative.dy + boundary.top,
      paint: fill,
    );
  }
}
