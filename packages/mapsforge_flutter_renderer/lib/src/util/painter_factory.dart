import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Factory class for creating appropriate shape painters for rendering instructions.
///
/// This factory provides a centralized way to create shape painters based on
/// rendering instruction types. It handles the complexity of painter creation,
/// caching, and type-specific initialization requirements.
///
/// Key features:
/// - Type-based painter creation with automatic detection
/// - Painter caching and reuse for performance
/// - Asynchronous initialization support
/// - Creation statistics tracking
/// - Special handling for context-dependent painters (captions)
class PainterFactory {
  static PainterFactory? _instance;

  final Cache<int, ShapePainter> _shapePainters = LruCache(capacity: 20000, onEvict: (_, test) => test.dispose(), name: "PainterFactory.Painters");

  PainterFactory._();

  factory PainterFactory() {
    _instance ??= PainterFactory._();
    return _instance!;
  }

  void dispose() {
    _shapePainters.clear();
  }

  ShapePainter<T>? getPainterForSerial<T extends Renderinstruction>(int serial) {
    return _shapePainters[serial] as ShapePainter<T>?;
  }

  void setPainterForSerial(int serial, ShapePainter painter) {
    _shapePainters[serial] = painter;
  }

  void removePainterForSerial(int serial) {
    _shapePainters.remove(serial);
  }

  /// Creates a shape painter for the given render information.
  ///
  /// Returns cached painter if available, otherwise creates a new painter
  /// based on the rendering instruction type. Some painters (like captions)
  /// are context-dependent and not cached for reuse.
  ///
  /// [renderInfo] Render information containing the instruction and context
  /// Returns appropriate shape painter for the instruction type
  Future<ShapePainter<T>> getOrCreateShapePainter<T extends Renderinstruction>(RenderInfo<T> renderInfo) async {
    if (renderInfo.shapePainter != null) return renderInfo.shapePainter!;

    ShapePainter? shapePainter = _shapePainters[renderInfo.renderInstruction.serial];
    if (shapePainter != null) {
      renderInfo.shapePainter = shapePainter as ShapePainter<T>;
      return shapePainter;
    }

    return await createShapePainter(renderInfo);
  }

  /// Creates a shape painter for the given render information.
  ///
  /// Returns cached painter if available, otherwise creates a new painter
  /// based on the rendering instruction type. Some painters (like captions)
  /// are context-dependent and not cached for reuse.
  ///
  /// [renderInfo] Render information containing the instruction and context
  /// Returns appropriate shape painter for the instruction type
  Future<ShapePainter<T>> createShapePainter<T extends Renderinstruction>(RenderInfo<T> renderInfo) async {
    switch (renderInfo.renderInstruction.getType()) {
      case "area":
        ShapePainter<T> shapePainter = await ShapePainterArea.create(renderInfo.renderInstruction as RenderinstructionArea) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "caption":
        ShapePainter<T> shapePainter = await ShapePainterCaption.create(renderInfo.renderInstruction as RenderinstructionCaption) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "circle":
        ShapePainter<T> shapePainter = await ShapePainterCircle.create(renderInfo.renderInstruction as RenderinstructionCircle) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      // case "Hillshading":
      //   shapePainter = ShapePaintHillshading(shape as ShapeHillshading) as ShapePainter<T>;
      //   break;
      case "icon":
        ShapePainter<T> shapePainter = await ShapePainterIcon.create(renderInfo.renderInstruction as RenderinstructionIcon) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "linesymbol":
        ShapePainter<T> shapePainter = await ShapePainterLinesymbol.create(renderInfo.renderInstruction as RenderinstructionLinesymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "polyline":
        // same as area but for open ways
        ShapePainter<T> shapePainter = await ShapePainterPolyline.create(renderInfo.renderInstruction as RenderinstructionPolyline) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "polylinetext":
        ShapePainter<T> shapePainter = await ShapePainterPolylineText.create(renderInfo.renderInstruction as RenderinstructionPolylineText) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "rect":
        ShapePainter<T> shapePainter = await ShapePainterRect.create(renderInfo.renderInstruction as RenderinstructionRect) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      case "symbol":
        ShapePainter<T> shapePainter = await ShapePainterSymbol.create(renderInfo.renderInstruction as RenderinstructionSymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        return shapePainter;
      default:
        throw Exception("cannot find ShapePaint for ${renderInfo.renderInstruction.getType()} of type ${renderInfo.runtimeType}");
    }
  }

  Future<void> initDrawingLayers(RenderInfoCollection renderInfoCollection) async {
    var session = PerformanceProfiler().startSession(category: "PainterFactory.initDrawingLayers");
    List<Future> futures = [];

    for (RenderInfo renderInfo in renderInfoCollection.renderInfos) {
      futures.add(getOrCreateShapePainter(renderInfo));
      if (futures.length > 200) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    await Future.wait(futures);
    session.complete();
  }
}
