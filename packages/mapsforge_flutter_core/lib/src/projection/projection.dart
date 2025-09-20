import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

/// An abstract class that defines the interface for a map projection.
///
/// A projection is responsible for converting between geographical coordinates
/// (latitude and longitude) and tile coordinates.
/// This class also provides utility methods for distance calculations and other
/// geo-related operations.
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

  static final BoundingBox BOUNDINGBOX_MAX = BoundingBox(LATITUDE_MIN, LONGITUDE_MIN, LATITUDE_MAX, LONGITUDE_MAX);

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

  /// Converts an angle from degrees to radians.
  static double degToRadian(final double deg) => deg * (pi / 180.0);

  /// Converts an angle from radians to degrees.
  static double radianToDeg(final double rad) => rad * (180.0 / pi);

  /// Normalizes an angle to the range [0, 360).
  static double normalizeRotation(double rotation) {
    double normalized = rotation % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  /// Calculates a destination point from a given starting point, distance, and bearing.
  ///
  /// This uses the Haversine formula to calculate the destination point along a
  /// great circle arc.
  static ILatLong offset(final ILatLong from, final double distanceInMeter, double bearing) {
    assert(bearing >= 0 && bearing <= 360);
    // bearing: 0: north, 90: east, 180: south, 270: west
    //bearing = 90 - bearing;

    // 0: east, 90: north, +/- 180: west, -90: south
    final double h = bearing / 180 * pi;

    final double a = distanceInMeter / EQUATORIAL_RADIUS;

    final double lat2 = asin(sin(degToRadian(from.latitude)) * cos(a) + cos(degToRadian(from.latitude)) * sin(a) * cos(h));

    final double lng2 =
        degToRadian(from.longitude) + atan2(sin(h) * sin(a) * cos(degToRadian(from.latitude)), cos(a) - sin(degToRadian(from.latitude)) * sin(lat2));

    return LatLong(radianToDeg(lat2), radianToDeg(lng2));
  }

  /// Calculates the initial bearing in degrees from point [p1] to point [p2].
  ///
  /// See https://www.movable-type.co.uk/scripts/latlong.html
  static double startBearing(final ILatLong p1, final ILatLong p2) {
    double longDiff = degToRadian(p2.longitude) - degToRadian(p1.longitude);
    double cosP2Lat = cos(degToRadian(p2.latitude));
    double y = sin(longDiff) * cosP2Lat;
    double x = cos(degToRadian(p1.latitude)) * sin(degToRadian(p2.latitude)) - sin(degToRadian(p1.latitude)) * cosP2Lat * cos(longDiff);
    double c = atan2(y, x);
    double result = (c * 180 / pi + 360) % 360;
    return result;
  }

  /// Calculates the great-circle distance in meters between two points using the
  /// Haversine formula.
  ///
  /// This formula is fast but can have an error of up to 0.3%.
  /// For higher accuracy, use [vincentyDistance].
  static double distance(final ILatLong p1, final ILatLong p2) {
    final sinDLat = sin((degToRadian(p2.latitude) - degToRadian(p1.latitude)) / 2);
    final sinDLng = sin((degToRadian(p2.longitude) - degToRadian(p1.longitude)) / 2);

    // Sides
    final a = sinDLat * sinDLat + sinDLng * sinDLng * cos(degToRadian(p1.latitude)) * cos(degToRadian(p2.latitude));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EQUATORIAL_RADIUS * c;
  }

  /// Calculates the geodetic distance in meters between two points using the
  /// Vincenty inverse formula for ellipsoids.
  ///
  /// This formula is very accurate but computationally more expensive than the
  /// Haversine formula.
  static double vincentyDistance(ILatLong latLong1, ILatLong latLong2) {
    double f = 1 / INVERSE_FLATTENING;
    double L = degToRadian(latLong2.longitude - latLong1.longitude);
    double U1 = atan((1 - f) * tan(degToRadian(latLong1.latitude)));
    double U2 = atan((1 - f) * tan(degToRadian(latLong2.latitude)));
    double sinU1 = sin(U1), cosU1 = cos(U1);
    double sinU2 = sin(U2), cosU2 = cos(U2);

    double lambda = L, lambdaP, iterLimit = 100;

    double cosSqAlpha = 0, sinSigma = 0, cosSigma = 0, cos2SigmaM = 0, sigma = 0, sinLambda = 0, sinAlpha = 0, cosLambda = 0;
    do {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
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
      lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) return 0; // formula failed to converge

    double uSq = cosSqAlpha * (EQUATORIAL_RADIUS * EQUATORIAL_RADIUS - POLAR_RADIUS * POLAR_RADIUS) / POLAR_RADIUS / POLAR_RADIUS;
    double A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    double B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    double deltaSigma =
        B *
        sinSigma *
        (cos2SigmaM +
            B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    double s = POLAR_RADIUS * A * (sigma - deltaSigma);

    return s;
  }

  /// Calculates a destination point from a given starting point, distance, and bearing.
  ///
  /// This is an alternative implementation to [offset].
  /// See http://www.movable-type.co.uk/scripts/latlon.js
  static ILatLong destinationPoint(ILatLong start, double distance, double bearing) {
    double theta = degToRadian(bearing);
    double delta = distance / EQUATORIAL_RADIUS; // angular distance in radians

    double phi1 = degToRadian(start.latitude);
    double lambda1 = degToRadian(start.longitude);

    double phi2 = asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
    double lambda2 = lambda1 + atan2(sin(theta) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2));

    return LatLong(radianToDeg(phi2), radianToDeg(lambda2));
  }

  /// Calculates the latitude difference in degrees for a given distance in meters.
  static double latitudeDistance(int meters) {
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS);
  }

  /// Calculates the longitude difference in degrees for a given distance in meters
  /// at a specific [latitude].
  static double longitudeDistance(int meters, double latitude) {
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS * cos(degToRadian(latitude)));
  }

  /////////////////////////////////////////////////////////////////////////////

  //double get scaleFactor;

  /// Converts a tile Y number to a latitude coordinate.
  double tileYToLatitude(int tileY);

  /// Converts a tile X number to a longitude coordinate.
  double tileXToLongitude(int tileX);

  /// Converts a latitude coordinate to a tile Y number.
  int latitudeToTileY(double latitude);

  /// Converts a longitude coordinate to a tile X number.
  int longitudeToTileX(double longitude);

  // BoundingBox boundingBoxOfTile(Tile tile);
  //
  // BoundingBox boundingBoxOfTiles(Tile upperLeft, Tile lowerRight);
}
