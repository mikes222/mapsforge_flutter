import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';

import '../rendertheme/shape/shape.dart';
import 'tilelayer.dart';

///
/// this class presents the whole map by requesting the tiles and drawing them when available
class TileLayerLabel extends TileLayer {
  static final _log = new Logger('TileLayerLabel');

  _Statistics? _statistics; // = _Statistics();

  TileLayerLabel() : super();

  @override
  void dispose() {
    if (_statistics != null) _log.info(_statistics.toString());
  }

  @override
  void draw(ViewModel viewModel, MapCanvas mapCanvas, JobSet jobSet) {
    Mappoint leftUpper =
        jobSet.mapViewPosition.getLeftUpper(viewModel.mapDimension);

    _statistics?.drawCount++;

    jobSet.renderInfos?.forEach((RenderInfo<Shape> renderInfo) {
      _statistics?.drawLabelCount++;
      renderInfo.render(mapCanvas, jobSet.mapViewPosition.projection, leftUpper,
          jobSet.mapViewPosition.rotationRadian);
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
