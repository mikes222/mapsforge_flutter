import 'package:mapsforge_flutter/core.dart';

class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Factory method to create a UserLocation from a Geolocator Position object
  factory UserLocation.fromPosition(ILatLong position) {
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  String toString() {
    return 'UserLocation {latitude: $latitude, longitude: $longitude.';
  }
}
