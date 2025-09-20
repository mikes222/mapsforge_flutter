/// An interface for a geographical point with latitude and longitude coordinates.
abstract class ILatLong {
  /// The latitude of this point in degrees.
  double get latitude;

  /// The longitude of this point in degrees.
  double get longitude;
}
