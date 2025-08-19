import 'package:dart_common/model.dart';

///
/// A request to produce a picture for a tile.
///
class JobRequest {
  /// A tile.
  final Tile tile;

  const JobRequest(this.tile);
}
