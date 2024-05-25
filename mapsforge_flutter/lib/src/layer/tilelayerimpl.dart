import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';

import 'tilelayer.dart';

///
/// this class presents the whole map by requesting the tiles and drawing them when available
class TileLayerImpl extends TileLayer {
  static final _log = new Logger('TileLayer');

  final MapPaint _paint;

  _Statistics? _statistics; // = _Statistics();

  TileLayerImpl()
      : _paint = GraphicFactory().createPaint(),
        super() {
    _paint.setAntiAlias(true);
  }

  @override
  void dispose() {
    if (_statistics != null) _log.info(_statistics.toString());
  }

  @override
  void draw(ViewModel viewModel, MapViewPosition mapViewPosition,
      MapCanvas mapCanvas, JobSet jobSet) {
    Mappoint leftUpper = mapViewPosition.getLeftUpper(viewModel.mapDimension);
    //_log.info("tiles: ${tiles.toString()}");

    // In a rotation situation it is possible that drawParentTileBitmap sets the
    // clipping bounds to portrait, while the device is just being rotated into
    // landscape: the result is a partially painted screen that only goes away
    // after zooming (which has the effect of resetting the clip bounds if drawParentTileBitmap
    // is called again).
    // Always resetting the clip bounds here seems to avoid the problem,
    // I assume that this is a pretty cheap operation, otherwise it would be better
    // to hook this into the onConfigurationChanged call chain.
    //canvas.resetClip();

    _statistics?.drawCount++;

    jobSet.bitmaps.forEach((Tile tile, JobResult jobResult) {
      if (jobResult.bitmap != null) {
        //_log.info("  $jobResult");
        _statistics?.drawBitmapCount++;
        Mappoint point = mapViewPosition.projection.getLeftUpper(tile);
        //print("drawing ${point.x - leftUpper.x} / ${point.y - leftUpper.y}");
        mapCanvas.drawBitmap(
          bitmap: jobResult.bitmap!,
          left: point.x - leftUpper.x,
          top: point.y - leftUpper.y,
          paint: _paint,
        );
      }
    });
  }
}

/////////////////////////////////////////////////////////////////////////////

class _Statistics {
  int drawCount = 0;

  int drawBitmapCount = 0;

  int drawLabelCount = 0;

  @override
  String toString() {
    return '_Statistics{drawCount: $drawCount, drawBitmapCount: $drawBitmapCount, drawLabelCount: $drawLabelCount}';
  }
}
