import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering polylines on the map.
///
/// This painter is responsible for drawing lines, such as roads and rivers.
/// It supports solid colors, dashed lines, and bitmap patterns for the stroke.
class ShapePainterPolyline extends UiShapePainter<RenderinstructionPolyline> {
  static final _log = Logger('ShapePainterPolyline');

  /// The paint used for the polyline stroke. Null if the stroke is transparent.
  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterPolyline");

  /// Creates a new polyline shape painter.
  ShapePainterPolyline._(RenderinstructionPolyline renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isStrokeTransparent() || renderinstruction.bitmapSrc != null) {
      stroke = UiPaint.stroke(
        color: renderinstruction.strokeColor,
        strokeWidth: renderinstruction.strokeWidth,
        cap: renderinstruction.strokeCap,
        join: renderinstruction.strokeJoin,
        strokeDasharray: renderinstruction.strokeDashArray,
      );
    } else {
      stroke = null;
    }
  }

  /// Creates a new polyline shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterPolyline> create(RenderinstructionPolyline renderinstruction) {
    return _taskQueue.add(() async {
      ShapePainterPolyline? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterPolyline?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterPolyline._(renderinstruction);
      await shapePainter.init();
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Initializes the shape painter by loading the bitmap pattern if specified.
  Future<void> init() async {
    if (renderinstruction.bitmapSrc != null) {
      try {
        SymbolImage? symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
          renderinstruction.bitmapSrc!,
          renderinstruction.getBitmapWidth(),
          renderinstruction.getBitmapHeight(),
        );
        if (symbolImage != null) {
          if (renderinstruction.isStrokeTransparent()) {
            // for bitmaps set the stroke color so that the bitmap is drawn
            stroke!.setColor(Colors.black);
          }
          stroke!.setBitmapShader(symbolImage);
          //symbolImage.dispose();
        }
      } catch (error) {
        _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
      }
    }
  }

  /// Polylines are not rendered for nodes.
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {}

  /// Renders a polyline for a way.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (stroke == null) return;

    UiPath path = calculatePath(wayProperties.getCoordinatesAbsolute(), renderContext.reference, renderinstruction.dy);
    renderContext.canvas.drawPath(path, stroke!);
  }
}
