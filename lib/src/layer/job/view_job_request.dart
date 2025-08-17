import '../../../core.dart';

class ViewJobRequest {
  final Tile upperLeft;

  final Tile lowerRight;

  ViewJobRequest(
      {required this.upperLeft,
      required this.lowerRight})
      : assert(upperLeft.zoomLevel == lowerRight.zoomLevel);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewJobRequest &&
          runtimeType == other.runtimeType &&
          upperLeft == other.upperLeft &&
          lowerRight == other.lowerRight ;

  @override
  int get hashCode =>
      upperLeft.hashCode ^ lowerRight.hashCode;
}
