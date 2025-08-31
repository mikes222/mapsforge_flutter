import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

abstract class RenderInfo<T extends Renderinstruction> {
  final T renderInstruction;

  /// The caption to draw. (used by renderinstructionCaption and renderinstructionPathtext)
  final String? caption;

  /// The painter to use for this renderinstruction.
  ShapePainter<T>? shapePainter;

  MapRectangle? boundaryAbsolute;

  RenderInfo(this.renderInstruction, {this.caption});

  void render(RenderContext renderContext);

  bool clashesWith(RenderInfo other);

  bool intersects(MapRectangle other);

  MapRectangle getBoundaryAbsolute();

  @override
  String toString() {
    return 'RenderInfo{renderInstruction: $renderInstruction, caption: $caption, shapePainter: $shapePainter}';
  }
}
