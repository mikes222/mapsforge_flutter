import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';

abstract class RenderInfo<T extends Renderinstruction> {
  final T renderInstruction;

  /// The caption to draw. (used by renderinstructionCaption and renderinstructionPathtext)
  String? caption;

  // The lines to draw (used by renderinstructionPathtext)
  LineSegmentPath? stringPath;

  /// The painter to use for this renderinstruction.
  ShapePainter<T>? shapePainter;

  MapRectangle? boundaryAbsolute;

  RenderInfo(this.renderInstruction);

  void render(RenderContext renderContext);

  bool clashesWith(RenderInfo other);

  bool intersects(MapRectangle other);

  MapRectangle getBoundaryAbsolute();
}
