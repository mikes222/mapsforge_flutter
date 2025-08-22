import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';

/// The base class for all ui-dependent painters
abstract class ShapePainter<T extends Renderinstruction> {
  final T renderinstruction;

  ShapePainter(this.renderinstruction);

  MapRectangle getBoundary();

  void renderNode(RenderContext renderContext, NodeProperties nodeProperties);

  void renderWay(RenderContext renderContext, WayProperties wayProperties);
}
