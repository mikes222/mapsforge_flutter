import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'job/jobset.dart';

///
/// this class presents the whole map by requesting the tiles and drawing them when available
abstract class TileLayer {
  TileLayer();

  /// Draws this {@code Layer} on the given canvas.
  ///
  /// @param boundingBox  the geographical area which should be drawn.
  /// @param zoomLevel    the zoom level at which this {@code Layer} should draw itself.
  /// @param canvas       the canvas on which this {@code Layer} should draw itself.
  /// @param topLeftPoint the top-left pixel position of the canvas relative to the top-left map position.
  void draw(ViewModel viewModel, MapCanvas canvas, JobSet jobSet);

  void dispose();
}
