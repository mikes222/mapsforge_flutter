import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/latlong_utils.dart';

class NanoLatLong implements ILatLong {
  final int _latitude;

  final int _longitude;

  NanoLatLong.fromNano(this._latitude, this._longitude);

  NanoLatLong.fromDegrees(double latitude, double longitude)
    : _latitude = LatLongUtils.degreesToNanodegrees(latitude),
      _longitude = LatLongUtils.degreesToNanodegrees(longitude);

  @override
  double get latitude => LatLongUtils.nanodegreesToDegrees(_latitude);

  @override
  double get longitude => LatLongUtils.nanodegreesToDegrees(_longitude);
}
