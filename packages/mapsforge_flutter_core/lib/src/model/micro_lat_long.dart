import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/latlong_utils.dart';

class MicroLatLong implements ILatLong {
  final int _latitude;

  final int _longitude;

  MicroLatLong.fromDegrees(double latitude, double longitude)
    : _latitude = LatLongUtils.degreesToMicrodegrees(latitude),
      _longitude = LatLongUtils.degreesToMicrodegrees(longitude);

  MicroLatLong(this._latitude, this._longitude);

  @override
  double get latitude => LatLongUtils.microdegreesToDegrees(_latitude);

  @override
  double get longitude => LatLongUtils.microdegreesToDegrees(_longitude);

  @override
  String toString() {
    return 'MicroLatLong{_latitude: $_latitude, _longitude: $_longitude}';
  }
}
