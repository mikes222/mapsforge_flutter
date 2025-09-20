import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_canvas.dart';

/// A render context that holds all the necessary information for rendering a map tile.
///
/// This includes the canvas to draw on, the projection for converting geo-coordinates
/// to pixel coordinates, and the current map rotation.
class UiRenderContext extends RenderContext {
  static final int MAX_DRAWING_LAYERS = 11;

  /// The canvas for this rendering
  final UiCanvas canvas;

  /// The reference mappoint for this rendering. This is usualy the center of the canvas in map pixel coordinates
  final Mappoint reference;

  /// The pixel projection for the current zoom level.
  final PixelProjection projection;

  /// The current map rotation in radians.
  double rotationRadian;

  /// Creates a new `UiRenderContext`.
  UiRenderContext({required this.canvas, required this.reference, required this.projection, this.rotationRadian = 0});

  @override
  String toString() {
    return 'UiRenderContext{reference: $reference, projection: $projection, rotationRadian: $rotationRadian}';
  }
}
