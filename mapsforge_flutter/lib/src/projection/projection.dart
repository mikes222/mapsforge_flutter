import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// This class provides the calculation from Lat/Lon to pixelY/pixelX and vice versa
///
abstract class Projection {
  /// The equatorial radius as defined by the <a href="http://en.wikipedia.org/wiki/World_Geodetic_System">WGS84
  /// ellipsoid</a>. WGS84 is the reference coordinate system used by the Global Positioning System.
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /// Polar radius of earth is required for distance computation.
  static final double POLAR_RADIUS = 6356752.3142;

  /// Maximum possible latitude coordinate of the map.
  static final double LATITUDE_MAX = 85.05112877980659;

  /// Minimum possible latitude coordinate of the map.
  static final double LATITUDE_MIN = -LATITUDE_MAX;

  /// The circumference of the earth at the equator in meters.
  static final double EARTH_CIRCUMFERENCE = 40075016.686;

  /// Polar radius in meter (WGS84 ellipsoid)
  //static final double POLAR_RADIUS = 6356752.314245;

  static final double LONGITUDE_MAX = 180;

  static final double LONGITUDE_MIN = -LONGITUDE_MAX;

  /// The flattening factor of the earth's ellipsoid is required for distance computation.
  static final double INVERSE_FLATTENING = 298.257223563;

//  static void checkLatitude(double latitude) {
  // assert(latitude >= LATITUDE_MIN);
  // assert(latitude <= LATITUDE_MAX);
//  }

//  static void checkLongitude(double longitude) {
  // assert(longitude >= LONGITUDE_MIN);
  // assert(longitude <= LONGITUDE_MAX);
//  }

  /// Converts degree to radian
  static double degToRadian(final double deg) => deg * (pi / 180.0);

  /// Radian to degree
  static double radianToDeg(final double rad) => rad * (180.0 / pi);

  /// Returns a destination point based on the given [distance] and [bearing]
  ///
  /// Given a [from] (start) point, initial [bearing], and [distance],
  /// this will calculate the destination point and
  /// final bearing travelling along a (shortest distance) great circle arc.
  ///
  ///     final Haversine distance = const Haversine();
  ///
  ///     final num distanceInMeter = (EARTH_RADIUS * math.PI / 4).round();
  ///
  ///     final p1 = new LatLng(0.0, 0.0);
  ///     final p2 = distance.offset(p1, distanceInMeter, 180);
  ///
  //@override
  static ILatLong offset(
      final ILatLong from, final double distanceInMeter, double bearing) {
    assert(bearing >= 0 && bearing <= 360);
// bearing: 0: north, 90: east, 180: south, 270: west
    //bearing = 90 - bearing;

    // 0: east, 90: north, +/- 180: west, -90: south
    final double h = bearing / 180 * pi;

    final double a = distanceInMeter / EQUATORIAL_RADIUS;

    final double lat2 = asin(sin(degToRadian(from.latitude)) * cos(a) +
        cos(degToRadian(from.latitude)) * sin(a) * cos(h));

    final double lng2 = degToRadian(from.longitude) +
        atan2(sin(h) * sin(a) * cos(degToRadian(from.latitude)),
            cos(a) - sin(degToRadian(from.latitude)) * sin(lat2));

    return new LatLong(radianToDeg(lat2), radianToDeg(lng2));
  }

  /// calculates the startbearing in degrees of the distance from [p1] to [p2]
  /// see https://www.movable-type.co.uk/scripts/latlong.html
  static double startBearing(final ILatLong p1, final ILatLong p2) {
    double longDiff = degToRadian(p2.longitude) - degToRadian(p1.longitude);
    double cosP2Lat = cos(degToRadian(p2.latitude));
    double y = sin(longDiff) * cosP2Lat;
    double x = cos(degToRadian(p1.latitude)) * sin(degToRadian(p2.latitude)) -
        sin(degToRadian(p1.latitude)) * cosP2Lat * cos(longDiff);
    double c = atan2(y, x);
    double result = (c * 180 / pi + 360) % 360;
    return result;
  }

  /// Calculates distance with Haversine algorithm.
  ///
  /// Accuracy can be out by 0.3%
  /// More on [Wikipedia](https://en.wikipedia.org/wiki/Haversine_formula)
  /// @return the distance in meters
  //@override
  static double distance(final ILatLong p1, final ILatLong p2) {
    final sinDLat =
        sin((degToRadian(p2.latitude) - degToRadian(p1.latitude)) / 2);
    final sinDLng =
        sin((degToRadian(p2.longitude) - degToRadian(p1.longitude)) / 2);

    // Sides
    final a = sinDLat * sinDLat +
        sinDLng *
            sinDLng *
            cos(degToRadian(p1.latitude)) *
            cos(degToRadian(p2.latitude));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EQUATORIAL_RADIUS * c;
  }

  /**
   * Calculates geodetic distance between two LatLongs using Vincenty inverse formula
   * for ellipsoids. This is very accurate but consumes more resources and time than the
   * sphericalDistance method.
   * <p/>
   * Adaptation of Chriss Veness' JavaScript Code on
   * http://www.movable-type.co.uk/scripts/latlong-vincenty.html
   * <p/>
   * Paper: Vincenty inverse formula - T Vincenty, "Direct and Inverse Solutions of Geodesics
   * on the Ellipsoid with application of nested equations", Survey Review, vol XXII no 176,
   * 1975 (http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)
   *
   * @param latLong1 first LatLong
   * @param latLong2 second LatLong
   * @return distance in meters between points as a double
   */
  static double vincentyDistance(ILatLong latLong1, ILatLong latLong2) {
    double f = 1 / INVERSE_FLATTENING;
    double L = degToRadian(latLong2.longitude - latLong1.longitude);
    double U1 = atan((1 - f) * tan(degToRadian(latLong1.latitude)));
    double U2 = atan((1 - f) * tan(degToRadian(latLong2.latitude)));
    double sinU1 = sin(U1), cosU1 = cos(U1);
    double sinU2 = sin(U2), cosU2 = cos(U2);

    double lambda = L, lambdaP, iterLimit = 100;

    double cosSqAlpha = 0,
        sinSigma = 0,
        cosSigma = 0,
        cos2SigmaM = 0,
        sigma = 0,
        sinLambda = 0,
        sinAlpha = 0,
        cosLambda = 0;
    do {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
              (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      if (sinSigma == 0) return 0; // co-incident points
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      if (cosSqAlpha != 0) {
        cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      } else {
        cos2SigmaM = 0;
      }
      double C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = L +
          (1 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SigmaM +
                          C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) return 0; // formula failed to converge

    double uSq = cosSqAlpha *
        (pow(EQUATORIAL_RADIUS, 2) - pow(POLAR_RADIUS, 2)) /
        pow(POLAR_RADIUS, 2);
    double A =
        1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    double B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    double deltaSigma = B *
        sinSigma *
        (cos2SigmaM +
            B /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    B /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    double s = POLAR_RADIUS * A * (sigma - deltaSigma);

    return s;
  }

  /// Returns the destination point from this point having travelled the given distance on the
  /// given initial bearing (bearing normally varies around path followed).
  ///
  /// @param start    the start point
  /// @param distance the distance travelled, in same units as earth radius (default: meters)
  /// @param bearing  the initial bearing in degrees from north
  /// @return the destination point
  /// @see <a href="http://www.movable-type.co.uk/scripts/latlon.js">latlon.js</a>
  static ILatLong destinationPoint(
      ILatLong start, double distance, double bearing) {
    double theta = degToRadian(bearing);
    double delta = distance / EQUATORIAL_RADIUS; // angular distance in radians

    double phi1 = degToRadian(start.latitude);
    double lambda1 = degToRadian(start.longitude);

    double phi2 =
        asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
    double lambda2 = lambda1 +
        atan2(sin(theta) * sin(delta) * cos(phi1),
            cos(delta) - sin(phi1) * sin(phi2));

    return new LatLong(radianToDeg(phi2), radianToDeg(lambda2));
  }

  /**
   * Calculates the amount of degrees of latitude for a given distance in meters.
   *
   * @param meters distance in meters
   * @return latitude degrees
   */
  static double latitudeDistance(int meters) {
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS);
  }

  /**
   * Calculates the amount of degrees of longitude for a given distance in meters.
   *
   * @param meters   distance in meters
   * @param latitude the latitude at which the calculation should be performed
   * @return longitude degrees
   */
  static double longitudeDistance(int meters, double latitude) {
    return (meters * 360) /
        (2 * pi * EQUATORIAL_RADIUS * cos(degToRadian(latitude)));
  }

  /////////////////////////////////////////////////////////////////////////////

  //double get scaleFactor;

  /// Converts a tile Y number at a certain zoom level to a latitude coordinate.
  ///
  /// @param tileY     the tile Y number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the latitude value of the tile Y number.
  double tileYToLatitude(int tileY);

  /// Converts a tile X number at a certain zoom level to a longitude coordinate.
  ///
  /// @param tileX     the tile X number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the longitude value of the tile X number.
  double tileXToLongitude(int tileX);

  /// Converts a latitude coordinate (in degrees) to a tile Y number at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number of the latitude value.
  int latitudeToTileY(double latitude);

  /// Converts a longitude coordinate (in degrees) to the tile X number at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number of the longitude value.
  int longitudeToTileX(double longitude);

  BoundingBox boundingBoxOfTile(Tile tile);

  BoundingBox boundingBoxOfTiles(Tile upperLeft, Tile lowerRight);
}
