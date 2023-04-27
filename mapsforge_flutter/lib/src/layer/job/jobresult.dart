import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';

import '../../rendertheme/renderinfo.dart';
import '../../rendertheme/shape/shape.dart';

class JobResult {
  final TileBitmap? bitmap;

  final JOBRESULT result;

  final List<RenderInfo<Shape>>? renderInfos;

  JobResult(this.bitmap, this.result, [this.renderInfos]);
}

/////////////////////////////////////////////////////////////////////////////

enum JOBRESULT {
  NORMAL,
  ERROR,

  /// the tile is not supported, there are no data available
  UNSUPPORTED
}
