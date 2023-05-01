import 'dart:math';

import '../../core.dart';

class RotateHelper {
  /// normalizes the given dx/dy coordinates in respect to the orientation.
  /// We rotate the given coordinates so that it behaves like there was NO
  /// rotation at all
  static PositionInfo? normalize(ViewModel viewModel, double dx, double dy) {
    Mappoint? leftUpper =
        viewModel.mapViewPosition?.getLeftUpper(viewModel.mapDimension);
    Mappoint? center = viewModel.mapViewPosition?.getCenter();
    if (center == null || leftUpper == null) {
      return null;
    }

    /// x/y relative from the center
    double diffX = leftUpper.x - center.x + dx * viewModel.viewScaleFactor;
    double diffY = leftUpper.y - center.y + dy * viewModel.viewScaleFactor;
    if (viewModel.mapViewPosition?.rotation != 0) {
      double hyp = sqrt(diffX * diffX + diffY * diffY);
      double rad = atan2(diffY, diffX);
      double rot = viewModel.mapViewPosition!.rotationRadian;
      diffX = cos(-rot + rad) * hyp;
      diffY = sin(-rot + rad) * hyp;
      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    // lat/lon of the position where we double-clicked
    double latitude = viewModel.mapViewPosition!.projection
        .pixelYToLatitude(center.y + diffY);
    double longitude = viewModel.mapViewPosition!.projection
        .pixelXToLongitude(center.x + diffX);
    return PositionInfo(
        dx: diffX,
        dy: diffY,
        latitude: latitude,
        longitude: longitude,
        center: center);
  }
}

/////////////////////////////////////////////////////////////////////////////

class PositionInfo implements ILatLong {
  /// relative distance from the center in x- (horizontal) direction. Positive
  /// values points towards right. Unit: Mappixels
  final double dx;

  /// relative distance from the center in y- (vertical) direction. Positive
  /// value towards bottom. Unit: Mappixels
  final double dy;

  /// The latitude of the given point
  @override
  final double latitude;

  /// The longitude of given point
  @override
  final double longitude;

  /// The center of the current view in mappixels
  final Mappoint center;

  const PositionInfo(
      {required this.dx,
      required this.dy,
      required this.latitude,
      required this.longitude,
      required this.center});
}
