import 'dart:math';

import 'package:mapsforge_flutter/datastore.dart';

import '../../core.dart';

class LatLongUtils {
  /**
   * The equatorial radius as defined by the <a href="http://en.wikipedia.org/wiki/World_Geodetic_System">WGS84
   * ellipsoid</a>. WGS84 is the reference coordinate system used by the Global Positioning System.
   */
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /// Polar radius of earth is required for distance computation.
  static final double POLAR_RADIUS = 6356752.3142;

  /// Conversion factor from degrees to microdegrees and vice versa.
  static final double CONVERSION_FACTOR = 1000000.0;

  static final double NANO_CONVERSION_FACTOR = 1000000000.0;

  static final String DELIMITER = ",";

  LatLongUtils._();

  /**
   * Find if the given point lies within this polygon.
   * <p>
   * http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
   *
   * @return true if this polygon contains the given point, false otherwise.
   */
  static bool contains(List<ILatLong> latLongs, ILatLong latLong) {
    bool result = false;
    for (int i = 0, j = latLongs.length - 1; i < latLongs.length; j = i++) {
      if ((latLongs[i].latitude > latLong.latitude) != (latLongs[j].latitude > latLong.latitude) &&
          (latLong.longitude <
              (latLongs[j].longitude - latLongs[i].longitude) * (latLong.latitude - latLongs[i].latitude) / (latLongs[j].latitude - latLongs[i].latitude) +
                  latLongs[i].longitude)) {
        result = !result;
      }
    }
    return result;
  }

  /**
   * Returns the distance between the given segment and point.
   * <p>
   * libGDX (Apache 2.0)
   */
  static double distanceSegmentPoint(double startX, double startY, double endX, double endY, double pointX, double pointY) {
    LatLong nearest = nearestSegmentPoint(startX, startY, endX, endY, pointX, pointY);
    return sqrt(pow(nearest.longitude - pointX, 2) + pow(nearest.latitude - pointY, 2));
  }

  /**
   * Creates a new LatLong from a comma-separated string of coordinates in the order latitude, longitude. All
   * coordinate values must be in degrees.
   *
   * @param latLongString the string that describes the LatLong.
   * @return a new LatLong with the given coordinates.
   * @throws IllegalArgumentException if the string cannot be parsed or describes an invalid LatLong.
   */
//  static LatLong fromString(String latLongString) {
//    List<double> coordinates = parseCoordinateString(latLongString, 2);
//    return new LatLong(coordinates[0], coordinates[1]);
//  }

  /// Calculate the Euclidean distance between two LatLongs in degrees using the Pythagorean
  /// theorem.
  ///
  /// @param latLong1 first LatLong
  /// @param latLong2 second LatLong
  /// @return distance in degrees as a double
  static double euclideanDistance(ILatLong latLong1, ILatLong latLong2) {
    return sqrt(pow(latLong1.longitude - latLong2.longitude, 2) + pow(latLong1.latitude - latLong2.latitude, 2));
  }

  static double euclideanDistanceSquared(ILatLong latLong1, ILatLong latLong2) {
    return pow(latLong1.longitude - latLong2.longitude, 2).toDouble() + pow(latLong1.latitude - latLong2.latitude, 2);
  }

  /**
   * Find if this way is closed.
   *
   * @return true if this way is closed, false otherwise.
   */
  static bool isClosedWay(List<ILatLong> latLongs) {
    if (latLongs.length < 3) return false;
    return isNear(latLongs.first, latLongs.last);
  }

  /// Returns true if the other point is equal or near this point.
  static bool isNear(ILatLong me, ILatLong other) {
    if (me.latitude == other.latitude && me.longitude == other.longitude) return true;
    if ((me.latitude - other.latitude).abs() <= 0.00005 && (me.longitude - other.longitude).abs() <= 0.00005) return true;
    return false;
  }

  /// Converts a coordinate from microdegrees (degrees * 10^6) to degrees. No validation is performed.
  ///
  /// @param coordinate the coordinate in microdegrees (degrees * 10^6).
  /// @return the coordinate in degrees.
  static double microdegreesToDegrees(int coordinate) {
    return coordinate / CONVERSION_FACTOR;
  }

  /// Converts a coordinate from degrees to microdegrees (degrees * 10^6). No validation is performed.
  ///
  /// @param coordinate the coordinate in microdegrees (degrees * 10^6).
  /// @return the coordinate in degrees.
  static int degreesToMicrodegrees(double coordinate) {
    return (coordinate * CONVERSION_FACTOR).round();
  }

  /// Converts a coordinate from nanodegrees (degrees * 10^9) to degrees. No validation is performed.
  static double nanodegreesToDegrees(int coordinate) {
    return coordinate / NANO_CONVERSION_FACTOR;
  }

  /// Converts a coordinate from degrees to nanodegrees (degrees * 10^9). No validation is performed.
  static int degreesToNanodegrees(double coordinate) {
    return (coordinate * NANO_CONVERSION_FACTOR).round();
  }

  /**
   * Returns a point on the segment nearest to the specified point.
   * <p>
   * libGDX (Apache 2.0)
   */
  static LatLong nearestSegmentPoint(double startX, double startY, double endX, double endY, double pointX, double pointY) {
    double xDiff = endX - startX;
    double yDiff = endY - startY;
    double length2 = xDiff * xDiff + yDiff * yDiff;
    if (length2 == 0) return LatLong(startY, startX);
    double t = ((pointX - startX) * (endX - startX) + (pointY - startY) * (endY - startY)) / length2;
    if (t < 0) return LatLong(startY, startX);
    if (t > 1) return LatLong(endY, endX);
    return LatLong(startY + t * (endY - startY), startX + t * (endX - startX));
  }

  /**
   * Parses a given number of comma-separated coordinate values from the supplied string.
   *
   * @param coordinatesString   a comma-separated string of coordinate values.
   * @param numberOfCoordinates the expected number of coordinate values in the string.
   * @return the coordinate values in the order they have been parsed from the string.
   * @throws IllegalArgumentException if the string is invalid or does not contain the given number of coordinate values.
   */
//  static List<double> parseCoordinateString(String coordinatesString,
//      int numberOfCoordinates) {
//    StringTokenizer stringTokenizer = new StringTokenizer(
//        coordinatesString, DELIMITER, true);
//    bool isDelimiter = true;
//    List<String> tokens = new ArrayList<>(numberOfCoordinates);
//
//    while (stringTokenizer.hasMoreTokens()) {
//      String token = stringTokenizer.nextToken();
//      isDelimiter = !isDelimiter;
//      if (isDelimiter) {
//        continue;
//      }
//
//      tokens.add(token);
//    }
//
//    if (isDelimiter) {
//      throw new Exception(
//          "invalid coordinate delimiter: " + coordinatesString);
//    } else if (tokens.length != numberOfCoordinates) {
//      throw new Exception(
//          "invalid number of coordinate values: " + coordinatesString);
//    }
//
//    List<double> coordinates = new double[numberOfCoordinates];
//    for (int i = 0; i < numberOfCoordinates; ++i) {
//      coordinates[i] = double.parse(tokens.get(i));
//    }
//    return coordinates;
//  }

  /**
   * Calculates the zoom level that allows to display the {@link BoundingBox} on a view with the {@link Dimension} and
   * tile size.
   *
   * @param dimension   the {@link Dimension} of the view.
   * @param boundingBox the {@link BoundingBox} to display.
   * @param tileSize    the size of the tiles.
   * @return the zoom level that allows to display the {@link BoundingBox} on a view with the {@link Dimension} and
   * tile size.
   */
//  static int zoomForBounds(
//      Dimension dimension, BoundingBox boundingBox, int tileSize) {
//    int mapSize = MercatorProjection.getMapSize(0, tileSize);
//    double pixelXMax = MercatorProjection.longitudeToPixelXAtMapSize(
//        boundingBox.maxLongitude, mapSize);
//    double pixelXMin = MercatorProjection.longitudeToPixelXAtMapSize(
//        boundingBox.minLongitude, mapSize);
//    double zoomX =
//        -1 * log((pixelXMax - pixelXMin).abs() / dimension.width) / log(2);
//    double pixelYMax = MercatorProjection.latitudeToPixelYWithMapSize(
//        boundingBox.maxLatitude, mapSize);
//    double pixelYMin = MercatorProjection.latitudeToPixelYWithMapSize(
//        boundingBox.minLatitude, mapSize);
//    double zoomY =
//        -1 * log((pixelYMax - pixelYMin).abs() / dimension.height) / log(2);
//    int zoom = min(zoomX, zoomY).floor();
//    if (zoom < 0) {
//      return 0;
//    }
//    if (zoom > 255) {
//      return 255;
//    }
//    return zoom;
//  }

  /// Determines if a point is inside or outside a polygon.
  ///
  /// Uses the "ray casting" algorithm to determine if a point is inside a polygon.
  ///
  /// Args:
  ///   point: The point to test (ILatLong).
  ///   polygon: A list of points (List<ILatLong>) that define the polygon.
  ///            The polygon must be closed (first and last point are the same).
  ///
  /// Returns:
  ///   True if the point is inside the polygon, false otherwise.
  static bool isPointInPolygon(ILatLong point, List<ILatLong> polygon) {
    assert(polygon.length >= 3);
    // Check if the polygon is valid.
    // if (polygon.length < 3 || polygon.first != polygon.last) {
    //   throw ArgumentError(
    //       'The polygon must have at least 3 points and must be closed (first and last points are the same).');
    // }

    // Ray casting algorithm
    int intersectionCount = 0;
    final double pointX = point.longitude;
    final double pointY = point.latitude;

    ILatLong? previous;

    polygon.forEach((current) {
      if (previous != null) {
        final double x1 = previous!.longitude;
        final double y1 = previous!.latitude;
        final double x2 = current.longitude;
        final double y2 = current.latitude;

        // Check if the ray intersects the current edge
        if (y1 <= pointY && y2 > pointY || y2 <= pointY && y1 > pointY) {
          // Calculate the intersection point of the ray with the current edge
          final double intersectionX = (x2 - x1) * (pointY - y1) / (y2 - y1) + x1;

          // If the intersection point is to the left of the test point, count it as an intersection
          if (pointX < intersectionX) {
            intersectionCount++;
          }
        }
      }
      previous = current;
    });

    // If the number of intersections is odd, the point is inside the polygon; otherwise, it's outside
    return intersectionCount % 2 == 1;
  }

  /// Checks if two line segments intersect. They do NOT intersect if the
  /// intersection point is outside of the given start-end points.
  ///
  /// @param line1Start Der Startpunkt des ersten Liniensegments.
  /// @param line1End Der Endpunkt des ersten Liniensegments.
  /// @param line2Start Der Startpunkt des zweiten Liniensegments.
  /// @param line2End Der Endpunkt des zweiten Liniensegments.
  /// @return `true`, wenn sich die Liniensegmente überschneiden, andernfalls `false`.
  static bool doLinesIntersect(ILatLong line1Start, ILatLong line1End, ILatLong line2Start, ILatLong line2End) {
    // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
    double x1 = line1Start.longitude;
    double y1 = line1Start.latitude;
    double x2 = line1End.longitude;
    double y2 = line1End.latitude;
    double x3 = line2Start.longitude;
    double y3 = line2Start.latitude;
    double x4 = line2End.longitude;
    double y4 = line2End.latitude;

    final x12diff = x1 - x2;
    final x34diff = x3 - x4;
    final y12diff = y1 - y2;
    final y34diff = y3 - y4;
    final denominator = x12diff * y34diff - y12diff * x34diff;

    if (denominator == 0.0) {
      // Die Linien sind parallel.
      return false;
    }

    final x13diff = x1 - x3;
    final y13diff = y1 - y3;
    final tNumerator = x13diff * y34diff - y13diff * x34diff;
    final uNumerator = -(x12diff * y13diff - y12diff * x13diff);

    double t = tNumerator / denominator;
    double u = uNumerator / denominator;

    return t >= 0.0 && t <= 1.0 && u >= 0 && u <= 1.0;
  }

  /// Findet den Schnittpunkt von zwei Liniensegmenten.
  ///
  /// @param line1Start Der Startpunkt des ersten Liniensegments.
  /// @param line1End Der Endpunkt des ersten Liniensegments.
  /// @param line2Start Der Startpunkt des zweiten Liniensegments.
  /// @param line2End Der Endpunkt des zweiten Liniensegments.
  /// @return Der Schnittpunkt als ILatLong oder null, wenn kein Schnittpunkt gefunden wurde.
  static ILatLong? getLineIntersection(ILatLong line1Start, ILatLong line1End, ILatLong line2Start, ILatLong line2End) {
    final x1 = line1Start.longitude;
    final y1 = line1Start.latitude;
    final x2 = line1End.longitude;
    final y2 = line1End.latitude;
    final x3 = line2Start.longitude;
    final y3 = line2Start.latitude;
    final x4 = line2End.longitude;
    final y4 = line2End.latitude;

    final x12diff = x1 - x2;
    final x34diff = x3 - x4;
    final y12diff = y1 - y2;
    final y34diff = y3 - y4;
    final denominator = x12diff * y34diff - y12diff * x34diff;

    if (denominator == 0.0) {
      // Die Linien sind parallel.
      return null;
    }

    final x13diff = x1 - x3;
    final y13diff = y1 - y3;
    final tNumerator = x13diff * y34diff - y13diff * x34diff;
    final uNumerator = -(x12diff * y13diff - y12diff * x13diff);

    final t = tNumerator / denominator;
    final u = uNumerator / denominator;

    if (t >= 0.0 && t <= 1.0 && u >= 0.0 && u <= 1.0) {
      final intersectionX = x1 + t * (x2 - x1);
      final intersectionY = y1 + t * (y2 - y1);
      return LatLong(intersectionY, intersectionX);
    }

    return null;
  }

  /// Finds the intersection point of two line segments whereas the second line segment is horizontal. This is a method which may be faster than the generic one
  /// in the case when the first line is above or below the second line.
  static ILatLong? getLineIntersectionHorizontal(ILatLong line1Start, ILatLong line1End, ILatLong line2Start, ILatLong line2End) {
    final y1 = line1Start.latitude;
    final y2 = line1End.latitude;
    final y3 = line2Start.latitude;

    // first lines is below or above the second line
    if (y1 > y3 && y2 > y3) return null;
    if (y1 < y3 && y2 < y3) return null;

    return getLineIntersection(line1Start, line1End, line2Start, line2End);
  }

  static ILatLong? getLineIntersectionVertical(ILatLong line1Start, ILatLong line1End, ILatLong line2Start, ILatLong line2End) {
    final x1 = line1Start.longitude;
    final x2 = line1End.longitude;
    final x3 = line2Start.longitude;

    if (x1 < x3 && x2 < x3) return null;
    if (x1 > x3 && x2 > x3) return null;

    return getLineIntersection(line1Start, line1End, line2Start, line2End);
  }

  static void printLatLongs(Way way) {
    way.latLongs.forEach((latlongs) {
      List<String> results = [];
      String result = "";
      latlongs.forEach((latlong) {
        result += "const LatLong(${(latlong.latitude).toStringAsFixed(6)},${(latlong.longitude).toStringAsFixed(6)}),";
        if (result.length > 250) {
          results.add(result);
          result = "";
        }
      });
      if (result.isNotEmpty) results.add(result);
      results.forEach((action) {
        print("  $action");
      });
    });
  }

  static String printWaypaths(Iterable<Waypath> waypaths) {
    if (waypaths.length <= 20) {
      return "${waypaths.map((toElement) => "${toElement.length}").toList()}";
    }
    return "${waypaths.take(20).map((toElement) => "${toElement.length}").toList()} (${waypaths.length} items)";
  }

  /// adds the [otherLatLongs] to [firstWaypath] in the correct order. Returns true if successful. Note that [firstWaypath] may be changed whereas
  /// [otherLatLongs] is never gonna be changed.
  static bool combine(Waypath firstWaypath, List<ILatLong> otherLatLongs) {
    if (LatLongUtils.isNear(firstWaypath.first, otherLatLongs.last)) {
      // add to the start of this list
      firstWaypath.removeAt(0);
      firstWaypath.insertAll(0, otherLatLongs);
      return true;
    } else if (LatLongUtils.isNear(firstWaypath.last, otherLatLongs.first)) {
      // add to end of this list
      firstWaypath.addAll(otherLatLongs.skip(1));
      return true;
    } else if (LatLongUtils.isNear(firstWaypath.first, otherLatLongs.first)) {
      // reversed order, add to start of the list in reversed order
      firstWaypath.removeAt(0);
      firstWaypath.insertAll(0, otherLatLongs.reversed);
      return true;
    } else if (LatLongUtils.isNear(firstWaypath.last, otherLatLongs.last)) {
      // reversed order, add to end of the list in reversed order
      firstWaypath.addAll(otherLatLongs.reversed.skip(1));
      return true;
    } else {
      return false;
    }
  }
}
