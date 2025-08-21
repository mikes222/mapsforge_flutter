import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';

class RenderInfo<T extends Renderinstruction> {
  final T renderInstruction;

  /// The caption to draw. (used by renderinstructionCaption and renderinstructionPathtext)
  String? caption;

  // The lines to draw (used by renderinstructionPathtext)
  LineString? stringPath;

  /// The painter to use for this renderinstruction.
  ShapePainter<T>? shapePainter;

  RenderInfo(this.renderInstruction);
}
