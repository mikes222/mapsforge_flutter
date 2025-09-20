import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_matrix.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering icons from a font on the map.
///
/// This painter is responsible for drawing icons using a specific character
/// from a font file. It handles the color, size, and rotation of the icon.
class ShapePainterIcon extends UiShapePainter<RenderinstructionIcon> {
  static final _log = Logger('ShapePainterIcon');

  static const bool debug = false;

  late final UiPaint fill;

  TextPainter? textPainter;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterIcon");

  ShapePainterIcon._(RenderinstructionIcon renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill(color: renderinstruction.getBitmapColor());
    init();
  }

  /// Creates a new icon shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterIcon> create(RenderinstructionIcon renderinstruction) async {
    return _taskQueue.add(() async {
      ShapePainterIcon? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterIcon?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterIcon._(renderinstruction);
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Initializes the [TextPainter] for rendering the icon.
  void init() {
    try {
      textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(renderinstruction.codePoint),
          style: TextStyle(
            fontSize: renderinstruction.getBitmapHeight().toDouble(),
            fontFamily: renderinstruction.fontFamily,
            color: Color(renderinstruction.getBitmapColor()),
            shadows: null,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter!.layout();
    } catch (error) {
      _log.warning("Error loading iconData ${renderinstruction.bitmapSrc}", error);
    }
  }

  /// Disposes the [TextPainter].
  @override
  void dispose() {
    textPainter?.dispose();
    textPainter = null;
  }

  /// Renders an icon for a node (e.g., a POI).
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (textPainter == null) return;
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
    renderContext.canvas.drawIcon(textPainter: textPainter!, left: relative.dx + boundary.left, top: relative.dy + boundary.top, matrix: matrix);
  }

  /// Renders an icon for a way.
  ///
  /// The icon is drawn at the center of the way's bounding box.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (textPainter == null) return;
    Mappoint point = wayProperties.getCenterAbsolute(renderContext.projection);
    MappointRelative relative = point.offset(renderContext.reference);
    MapRectangle boundary = renderinstruction.getBoundary(renderInfo);
    UiMatrix? matrix;
    if (renderinstruction.theta != 0 || renderContext.rotationRadian != 0) {
      matrix = UiMatrix();
      matrix.rotate(renderinstruction.theta - renderContext.rotationRadian, pivotX: boundary.left, pivotY: boundary.top);
    }

    renderContext.canvas.drawIcon(textPainter: textPainter!, left: relative.dx + boundary.left, top: relative.dy + boundary.top, matrix: matrix);
  }
}
