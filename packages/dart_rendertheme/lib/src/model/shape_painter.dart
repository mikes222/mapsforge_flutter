import 'package:dart_rendertheme/renderinstruction.dart';

/// The base class for all ui-dependent painters
class ShapePainter<T extends Renderinstruction> {
  final T renderinstruction;

  ShapePainter(this.renderinstruction);
}
