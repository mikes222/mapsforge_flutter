import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';

/// The base class for all ui-dependent painters
abstract class ShapePainter<T extends Renderinstruction> {
  final T renderinstruction;

  ShapePainter(this.renderinstruction);

  void renderNode<U extends RenderContext>(RenderContext<U> renderContext, NodeProperties nodeProperties);

  void renderWay<U extends RenderContext>(RenderContext<U> renderContext, WayProperties wayProperties);
}
