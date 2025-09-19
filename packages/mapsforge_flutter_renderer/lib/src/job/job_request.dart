import 'package:mapsforge_flutter_core/model.dart';

/// Request object for tile rendering operations.
///
/// This class encapsulates the parameters needed to render a map tile,
/// including the primary tile coordinates and optional multi-tile rendering
/// support for larger areas or higher resolution output.
///
/// Key features:
/// - Single tile rendering support
/// - Multi-tile rendering with tile ranges
/// - Zoom level and indoor level validation
/// - Immutable request parameters
class JobRequest {
  /// Primary tile to render, or upper-left tile for multi-tile rendering.
  final Tile tile;

  /// Optional lower-right tile for multi-tile rendering areas.
  ///
  /// When specified, defines a rectangular area from the primary tile
  /// to this tile for batch rendering operations.
  final Tile? rightLower;

  /// Creates a new job request for tile rendering.
  ///
  /// [tile] Primary tile coordinates to render
  /// [rightLower] Optional lower-right tile for multi-tile rendering
  ///
  /// Throws AssertionError if multi-tile parameters have mismatched zoom or indoor levels
  JobRequest(this.tile, [this.rightLower]) {
    assert(rightLower == null || tile.zoomLevel == rightLower!.zoomLevel, 'Multi-tile rendering requires matching zoom levels');
    assert(rightLower == null || tile.indoorLevel == rightLower!.indoorLevel, 'Multi-tile rendering requires matching indoor levels');
  }
}
