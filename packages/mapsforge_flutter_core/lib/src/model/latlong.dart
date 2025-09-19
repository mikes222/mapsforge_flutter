import 'package:mapsforge_flutter_core/src/utils/latlong_utils.dart';

import 'ilatlong.dart';

/// Immutable geographic coordinate representing a point on Earth's surface.
///
/// This class stores latitude and longitude values in decimal degrees using the WGS84
/// coordinate system. It provides conversion utilities for microdegrees (degrees * 10^6)
/// and supports parsing from various string formats.
///
/// Key features:
/// - Immutable design for thread safety
/// - WGS84 coordinate system compliance
/// - Microdegree conversion for high-precision storage
/// - String parsing with multiple separator support
/// - Efficient equality comparison and hashing
class LatLong implements ILatLong {
  /// Conversion factor from degrees to microdegrees.
  static final double CONVERSION_FACTOR = 1000000.0;

  /**
   * The RegEx pattern to read WKT points.
   */
  //  static final Pattern WKT_POINT_PATTERN =
  //      Pattern.compile(".*POINT\\s?\\(([\\d\\.]+)\\s([\\d\\.]+)\\).*");

  /// The internal latitude value.
  @override
  final double latitude;

  /// The internal longitude value.
  @override
  final double longitude;

  /// Converts a coordinate from degrees to microdegrees (degrees × 10^6).
  ///
  /// Microdegrees provide integer representation of coordinates with sub-meter precision.
  /// No validation is performed on the input coordinate.
  ///
  /// [coordinate] The coordinate value in decimal degrees
  /// Returns the coordinate as an integer in microdegrees
  static int degreesToMicrodegrees(double coordinate) {
    return (coordinate * CONVERSION_FACTOR).floor();
  }

  /// Creates a new LatLong with the specified coordinates in decimal degrees.
  ///
  /// [latitude] The latitude value in degrees (-90.0 to +90.0)
  /// [longitude] The longitude value in degrees (-180.0 to +180.0)
  ///
  /// Note: Coordinate validation is currently disabled but may be re-enabled
  const LatLong(this.latitude, this.longitude);

  // {
  //   Projection.checkLatitude(latitude);
  //   Projection.checkLongitude(longitude);
  // }

  /**
   * Constructs a new LatLong from a Well-Known-Text (WKT) representation of a point.
   * For example: POINT(13.4125 52.52235)
   * <p/>
   * WKT is used in PostGIS and other spatial databases.
   *
   * @param wellKnownText is the WKT point which describes the new LatLong, this needs to be in
   *                      degrees using a WGS84 representation. The coordinate order in the POINT is
   *                      defined as POINT(int lat).
   */
  //  LatLong._(String wellKnownText) {
  //    Matcher m = WKT_POINT_PATTERN.matcher(wellKnownText);
  //    m.matches();
  //    this.longitude = LatLongUtils.validateLongitude(double.parse(m.group(1)));
  //    this.latitude = LatLongUtils.validateLatitude(double.parse(m.group(2)));
  //  }

  /**
   * Returns the destination point from this point having travelled the given distance on the
   * given initial bearing (bearing normally varies around path followed).
   *
   * @param distance the distance travelled, in same units as earth radius (default: meters)
   * @param bearing  the initial bearing in degrees from north
   * @return the destination point
   * @see <a href="http://www.movable-type.co.uk/scripts/latlon.js">latlon.js</a>
   */
  // LatLong destinationPoint(double distance, double bearing) {
  //   return LatLongUtils.destinationPoint(this, distance, bearing);
  // }

  /**
   * Calculate the Euclidean distance from this LatLong to another.
   *
   * @param other The LatLong to calculate the distance to
   * @return the distance in degrees as a double
   */
  // double distance(LatLong other) {
  //   return LatLongUtils.distance(this, other);
  // }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LatLong && runtimeType == other.runtimeType && latitude == other.latitude && longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  /// Creates a LatLong from microdegree coordinates.
  ///
  /// Converts microdegree values (degrees × 10^6) back to decimal degrees.
  /// This is useful when working with high-precision integer coordinate storage.
  ///
  /// [latitudeE6] The latitude value in microdegrees
  /// [longitudeE6] The longitude value in microdegrees
  /// Returns a new LatLong with converted decimal degree values
  static LatLong fromMicroDegrees(int latitudeE6, int longitudeE6) {
    return new LatLong(LatLongUtils.microdegreesToDegrees(latitudeE6), LatLongUtils.microdegreesToDegrees(longitudeE6));
  }

  /// Parses a LatLong from a string with latitude and longitude values.
  ///
  /// Supports multiple separators: comma (,), semicolon (;), colon (:), and whitespace.
  /// The format should be "latitude,longitude" or similar with supported separators.
  ///
  /// [latLonString] String containing the coordinate values
  /// Returns a new LatLong parsed from the string
  /// Throws Exception if the string format is invalid
  static LatLong fromString(String latLonString) {
    List<String> split = latLonString.split("[,;:\\s]");
    if (split.length != 2) throw new Exception("cannot read coordinate, not a valid format");
    double latitude = double.parse(split[0]);
    double longitude = double.parse(split[1]);
    return new LatLong(latitude, longitude);
  }

  /// Gets the latitude value in decimal degrees.
  ///
  /// Returns the latitude coordinate (-90.0 to +90.0)
  double? getLatitude() {
    return this.latitude;
  }

  /// Gets the latitude value in microdegrees.
  ///
  /// Returns the latitude as an integer in microdegrees (degrees × 10^6)
  int getLatitudeE6() {
    return degreesToMicrodegrees(this.latitude);
  }

  /// Gets the longitude value in decimal degrees.
  ///
  /// Returns the longitude coordinate (-180.0 to +180.0)
  double? getLongitude() {
    return this.longitude;
  }

  /// Gets the longitude value in microdegrees.
  ///
  /// Returns the longitude as an integer in microdegrees (degrees × 10^6)
  int getLongitudeE6() {
    return degreesToMicrodegrees(this.longitude);
  }

  /**
   * Calculate the spherical distance from this LatLong to another.
   * <p/>
   * Use vincentyDistance for more accuracy but less performance.
   *
   * @param other The LatLong to calculate the distance to
   * @return the distance in meters as a double
   */
  // double sphericalDistance(LatLong other) {
  //   return LatLongUtils.sphericalDistance(this, other);
  // }

  @override
  String toString() {
    return 'LatLong{$latitude/$longitude}';
  }

  /**
 * Calculate the spherical distance from this LatLong to another.
 * <p/>
 * Use "distance" for faster computation with less accuracy.
 *
 * @param other The LatLong to calculate the distance to
 * @return the distance in meters as a double
 */
  // double vincentyDistance(LatLong other) {
  //   return LatLongUtils.vincentyDistance(this, other);
  // }
}
