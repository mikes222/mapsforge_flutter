import 'package:mapsforge_flutter_rendertheme/src/model/render_info_collection.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

/// Result object containing the output of a tile rendering job.
///
/// This class encapsulates the results of a rendering operation, including
/// the generated tile picture, rendering status, and optional render information
/// for label extraction and debugging purposes.
///
/// Key features:
/// - Multiple result states (normal, error, unsupported)
/// - Optional tile picture output
/// - Render information for label extraction
/// - Factory constructors for different result types
///
/// Note that the jobResult may hold a [TilePicture] object which must be disposed after use.
class JobResult {
  /// Generated tile picture, null if rendering failed or unsupported.
  final TilePicture? _picture;

  /// Status of the rendering operation.
  final JOBRESULT _result;

  /// Optional render information for label extraction and debugging.
  final RenderInfoCollection? _renderInfo;

  /// Creates a successful job result with optional render information.
  ///
  /// [_picture] Successfully generated tile picture
  /// [_renderInfo] Optional render information for labels
  JobResult.normal(this._picture, [this._renderInfo]) : assert(_picture != null), _result = JOBRESULT.NORMAL;

  /// [_renderInfo] render information for labels
  JobResult.normalLabels(this._renderInfo) : assert(_renderInfo != null), _result = JOBRESULT.NORMAL, _picture = null;

  /// Creates an error job result with optional error picture.
  ///
  /// [_picture] Optional picture containing error visualization
  JobResult.error(this._picture) : assert(_picture != null), _result = JOBRESULT.ERROR, _renderInfo = null;

  /// Creates an unsupported job result for tiles with no data.
  JobResult.unsupported() : _result = JOBRESULT.UNSUPPORTED, _renderInfo = null, _picture = null;

  /// Gets the generated tile picture, null if unavailable.
  TilePicture? get picture => _picture;

  /// Gets the rendering operation status.
  JOBRESULT get result => _result;

  /// Gets the render information for label extraction, null if unavailable.
  RenderInfoCollection? get renderInfo => _renderInfo;

  @override
  String toString() {
    return 'JobResult{_picture: $_picture, _result: $_result, _renderInfo: $_renderInfo}';
  }
}

/// Enumeration of possible job result states.
///
/// Defines the different outcomes of a tile rendering operation,
/// allowing consumers to handle success, error, and unsupported cases appropriately.
enum JOBRESULT {
  /// Successful rendering with tile picture available.
  NORMAL,

  /// Rendering error occurred, optional error picture may be available.
  ERROR,

  /// Tile is not supported due to lack of data or unsupported features.
  UNSUPPORTED,
}
