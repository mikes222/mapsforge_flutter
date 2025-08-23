import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_path.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintPolyline extends UiShapePainter<RenderinstructionPolyline> {
  static final _log = Logger('ShapePaintPolyline');

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPolyline._(RenderinstructionPolyline renderinstruction) : super(renderinstruction) {
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

  static Future<ShapePaintPolyline> create(RenderinstructionPolyline renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintPolyline;
      ShapePaintPolyline shapePaint = ShapePaintPolyline._(renderinstruction);
      await shapePaint.init();
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

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
          symbolImage.dispose();
        }
      } catch (error) {
        _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
      }
    }
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (stroke == null) return;
    UiPath path = calculatePath(wayProperties.getCoordinatesAbsolute(), renderContext.reference, renderinstruction.dy);
    renderContext.canvas.drawPath(path, stroke!);
  }
}
