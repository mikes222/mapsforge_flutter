import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:datastore_renderer/src/ui/ui_canvas.dart';

class UiRenderContext extends RenderContext {
  static final int MAX_DRAWING_LAYERS = 11;

  /// The canvas for this rendering
  final UiCanvas canvas;

  /// The reference mappoint for this rendering. This is usualy the center of the canvas in map pixel coordinates
  final Mappoint reference;

  final PixelProjection projection;

  double rotationRadian;

  UiRenderContext({required this.canvas, required this.reference, required this.projection, this.rotationRadian = 0});

  @override
  String toString() {
    return 'UiRenderContext{reference: $reference, projection: $projection, rotationRadian: $rotationRadian}';
  }
}
