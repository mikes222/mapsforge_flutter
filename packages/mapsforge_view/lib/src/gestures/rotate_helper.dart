import 'dart:math';
import 'dart:ui' as ui;

import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:mapsforge_view/mapsforge.dart';

class RotateHelper {
  /// normalizes the given dx/dy coordinates in respect to the orientation.
  /// We rotate the given coordinates so that it behaves like there was NO
  /// rotation at all
  static PositionInfo? normalize(MapPosition position, ui.Size size, double dx, double dy) {
    // Mappoint? leftUpper =
    //     viewModel.mapViewPosition?.getLeftUpper(viewModel.mapDimension);
    Mappoint center = position.getCenter();

    /// x/y relative from the center
    double diffX = (dx - size.width / 2) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    double diffY = (dy - size.height / 2) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    if (position.rotation != 0) {
      double hyp = sqrt(diffX * diffX + diffY * diffY);
      double rad = atan2(diffY, diffX);
      double rot = position.rotationRadian;
      diffX = cos(-rot + rad) * hyp;
      diffY = sin(-rot + rad) * hyp;
      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    // lat/lon of the position where we double-clicked
    ILatLong latLong = position.projection.pixelToLatLong(center.x + diffX, center.y + diffY);
    return PositionInfo(
      dx: diffX,
      dy: diffY,
      latitude: latLong.latitude,
      longitude: latLong.longitude,
      center: center,
      mappoint: Mappoint(center.x + diffX, center.y + diffY),
    );
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

  /// The point of the event in mappixels
  final Mappoint mappoint;

  const PositionInfo({required this.dx, required this.dy, required this.latitude, required this.longitude, required this.center, required this.mappoint});

  @override
  String toString() {
    return 'PositionInfo{dx: $dx, dy: $dy, latitude: $latitude, longitude: $longitude, center: $center}';
  }
}
