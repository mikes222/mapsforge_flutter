import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';

/// The base class for all ui-dependent painters
abstract class ShapePainter<T extends Renderinstruction> {
  final T renderinstruction;

  ShapePainter(this.renderinstruction);

  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties);

  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties);

  /// ShapePainterLineSymbol and ShapePainterSymbol holds [SymbolImage] instances which must be disposed after use.
  void dispose() {}
}
