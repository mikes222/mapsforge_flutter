import 'package:dart_common/model.dart';

///
/// A request to produce a picture for a tile.
///
class JobRequest {
  /// A tile or the left-upper tile
  final Tile tile;

  final Tile? rightLower;

  JobRequest(this.tile, [this.rightLower]) {
    assert(rightLower == null || tile.zoomLevel == rightLower!.zoomLevel);
    assert(rightLower == null || tile.indoorLevel == rightLower!.indoorLevel);
  }
}
