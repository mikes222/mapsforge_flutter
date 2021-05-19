import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';

class JobResult {
  final TileBitmap? bitmap;

  final JOBRESULT result;

  JobResult(this.bitmap, this.result);
}

/////////////////////////////////////////////////////////////////////////////

enum JOBRESULT {
  NORMAL,
  ERROR,

  /// the tile is not supported, there are no data available
  UNSUPPORTED
}
