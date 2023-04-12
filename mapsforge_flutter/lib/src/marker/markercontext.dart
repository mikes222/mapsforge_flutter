import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';

import '../../core.dart';
import 'markercallback.dart';

class MarkerContext implements MarkerCallback {
  @override
  final FlutterCanvas flutterCanvas;

  @override
  final MapViewPosition mapViewPosition;

  /// The factor to scale down the map. With [DisplayModel.deviceScaleFactor] one can scale up the view and make it bigger. With this value
  /// one can scale down the view and make the resolution of the map better. This comes with the cost of increased tile image sizes and thus increased time for creating the tile-images
  @override
  final double viewScaleFactor;

  @override
  final ViewModel viewModel;

  const MarkerContext(this.flutterCanvas, this.mapViewPosition,
      this.viewScaleFactor, this.viewModel);

  @override
  void renderPathText(String caption, LineString lineString, Mappoint origin,
      MapPaint stroke, MapTextPaint textPaint, double maxTextWidth) {
    flutterCanvas.drawPathText(
        caption, lineString, origin, stroke, textPaint, maxTextWidth);
  }

  @override
  void renderPath(MapPath path, MapPaint paint) {
    flutterCanvas.drawPath(path, paint);
  }
}
