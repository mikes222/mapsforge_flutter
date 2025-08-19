import 'package:datastore_renderer/src/model/render_info_collection.dart';
import 'package:datastore_renderer/src/model/tile_picture.dart';

class JobResult {
  final TilePicture? _picture;

  final JOBRESULT _result;

  final RenderInfoCollection? _renderInfo;

  JobResult.normal(this._picture, [this._renderInfo]) : _result = JOBRESULT.NORMAL;

  JobResult.error(this._picture) : _result = JOBRESULT.ERROR, _renderInfo = null;

  JobResult.unsupported() : _result = JOBRESULT.NORMAL, _renderInfo = null, _picture = null;
}

/////////////////////////////////////////////////////////////////////////////

enum JOBRESULT {
  /// Normal result, picture is available
  NORMAL,

  /// Error occured, a picture with the error message is available
  ERROR,

  /// the tile is not supported, there are no data available
  UNSUPPORTED,
}
