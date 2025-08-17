import '../../graphics/tilepicture.dart';
import '../../rendertheme/renderinfo.dart';
import '../../rendertheme/shape/shape.dart';

class JobResult {
  final TilePicture? picture;

  final JOBRESULT result;

  final List<RenderInfo<Shape>>? renderInfos;

  JobResult(this.picture, this.result, [this.renderInfos]);
}

/////////////////////////////////////////////////////////////////////////////

enum JOBRESULT {
  NORMAL,
  ERROR,

  /// the tile is not supported, there are no data available
  UNSUPPORTED
}
