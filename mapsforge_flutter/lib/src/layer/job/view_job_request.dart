import '../../../core.dart';

class ViewJobRequest {
  final Tile upperLeft;

  final Tile lowerRight;

  /// The size of the requested tile. Same as viewModel.displayModel.tileSize
  final int tileSize;

  ViewJobRequest(
      {required this.upperLeft,
      required this.lowerRight,
      required this.tileSize})
      : assert(upperLeft.zoomLevel == lowerRight.zoomLevel);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewJobRequest &&
          runtimeType == other.runtimeType &&
          upperLeft == other.upperLeft &&
          lowerRight == other.lowerRight &&
          tileSize == other.tileSize;

  @override
  int get hashCode =>
      upperLeft.hashCode ^ lowerRight.hashCode ^ tileSize.hashCode;
}
