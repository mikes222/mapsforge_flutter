import '../utils/latlongutils.dart';
import 'ilatlong.dart';

/// This immutable class represents a geographic coordinate with a latitude and longitude value.
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

  /// Converts a coordinate from degrees to microdegrees (degrees * 10^6). No validation is performed.
  ///
  /// @param coordinate the coordinate in degrees.
  /// @return the coordinate in microdegrees (degrees * 10^6).
  static int degreesToMicrodegrees(double coordinate) {
    return (coordinate * CONVERSION_FACTOR).floor();
  }

  /// Constructs a new LatLong with the given latitude and longitude values, measured in
  /// degrees.
  ///
  /// @param latitude  the latitude value in degrees.
  /// @param longitude the longitude value in degrees.
  /// @throws IllegalArgumentException if the latitude or longitude value is invalid.
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
      identical(this, other) ||
      other is LatLong &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  /**
   * Constructs a new LatLong with the given latitude and longitude values, measured in
   * microdegrees.
   *
   * @param latitudeE6  the latitude value in microdegrees.
   * @param longitudeE6 the longitude value in microdegrees.
   * @return the LatLong
   * @throws IllegalArgumentException if the latitudeE6 or longitudeE6 value is invalid.
   */
  static LatLong fromMicroDegrees(int latitudeE6, int longitudeE6) {
    return new LatLong(LatLongUtils.microdegreesToDegrees(latitudeE6),
        LatLongUtils.microdegreesToDegrees(longitudeE6));
  }

  /**
   * Constructs a new LatLong from a comma-separated String containing latitude and
   * longitude values (also ';', ':' and whitespace work as separator).
   * Latitude and longitude are interpreted as measured in degrees.
   *
   * @param latLonString the String containing the latitude and longitude values
   * @return the LatLong
   * @throws IllegalArgumentException if the latLonString could not be interpreted as a coordinate
   */
  static LatLong fromString(String latLonString) {
    List<String> split = latLonString.split("[,;:\\s]");
    if (split.length != 2)
      throw new Exception("cannot read coordinate, not a valid format");
    double latitude = double.parse(split[0]);
    double longitude = double.parse(split[1]);
    return new LatLong(latitude, longitude);
  }

  /**
   * Returns the latitude value of this coordinate.
   *
   * @return the latitude value of this coordinate.
   */
  double? getLatitude() {
    return this.latitude;
  }

  /**
   * Returns the latitude value in microdegrees of this coordinate.
   *
   * @return the latitude value in microdegrees of this coordinate.
   */
  int getLatitudeE6() {
    return degreesToMicrodegrees(this.latitude);
  }

  /**
   * Returns the longitude value of this coordinate.
   *
   * @return the longitude value of this coordinate.
   */
  double? getLongitude() {
    return this.longitude;
  }

  /**
   * Returns the longitude value in microdegrees of this coordinate.
   *
   * @return the longitude value in microdegrees of this coordinate.
   */
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
    return 'LatLong{latitude: $latitude, longitude: $longitude}';
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
