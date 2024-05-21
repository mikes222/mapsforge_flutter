import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapsforge_flutter/core.dart';

class Pos implements ILatLong {
  final double lat;
  final double lon;
  double altitude;
  Pos(this.lat, this.lon, {this.altitude = 0});

  @override
  get latitude => lat;
  @override
  get longitude => lon;

  factory Pos.fromPosition(geo.Position p) {
    return Pos(p.latitude, p.longitude);
  }
}
