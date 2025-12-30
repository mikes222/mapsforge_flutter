import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

/// Utility class for geographic coordinate calculations and geometric operations.
///
/// This class provides a comprehensive set of static methods for working with
/// geographic coordinates, including:
/// - Point-in-polygon testing
/// - Line segment intersections
/// - Distance calculations
/// - Coordinate system conversions
/// - Geometric analysis of paths and polygons
///
/// All methods are static and the class cannot be instantiated.
class LatLongUtils {
  /// WGS84 equatorial radius in meters.
  ///
  /// The equatorial radius of Earth as defined by the WGS84 ellipsoid,
  /// which is the reference coordinate system used by GPS.
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /// WGS84 polar radius in meters.
  /// Used for accurate distance computations on the Earth's ellipsoid.
  static final double POLAR_RADIUS = 6356752.3142;

  /// Conversion factor between degrees and microdegrees (10^6).
  static final double CONVERSION_FACTOR = 1000000.0;

  /// Conversion factor between degrees and nanodegrees (10^9).
  static final double NANO_CONVERSION_FACTOR = 1000000000.0;

  /// Standard delimiter for coordinate string parsing.
  static final String DELIMITER = ",";

  /// Private constructor to prevent instantiation.
  LatLongUtils._();

  /// Tests if a point lies within a polygon using the ray casting algorithm.
  ///
  /// Implementation based on the PNPOLY algorithm.
  /// Reference: http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
  ///
  /// [latLongs] Vertices of the polygon
  /// [latLong] Point to test
  /// Returns true if the point is inside the polygon
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

  /// Returns the distance between the given segment and point.
  /// <p>
  /// libGDX (Apache 2.0)
  static double distanceSegmentPoint(double startX, double startY, double endX, double endY, double pointX, double pointY) {
    LatLong nearest = nearestSegmentPoint(startX, startY, endX, endY, pointX, pointY);
    return sqrt((nearest.longitude - pointX) * (nearest.longitude - pointX) + (nearest.latitude - pointY) + (nearest.latitude - pointY));
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

  /// Calculates Euclidean distance between two coordinates in degrees.
  ///
  /// Uses the Pythagorean theorem for fast approximate distance calculation.
  /// Note: This is not accurate for large distances due to Earth's curvature.
  ///
  /// [latLong1] First coordinate
  /// [latLong2] Second coordinate
  /// Returns distance in degrees
  static double euclideanDistance(ILatLong latLong1, ILatLong latLong2) {
    return sqrt(euclideanDistanceSquared(latLong1, latLong2));
  }

  static double euclideanDistanceSquared(ILatLong latLong1, ILatLong latLong2) {
    return (latLong1.longitude - latLong2.longitude) * (latLong1.longitude - latLong2.longitude) +
        (latLong1.latitude - latLong2.latitude) * (latLong1.latitude - latLong2.latitude);
  }

  /// Find if this way is closed.
  ///
  /// @return true if this way is closed, false otherwise.
  static bool isClosedWay(List<ILatLong> latLongs) {
    if (latLongs.length < 3) return false;
    return isNear(latLongs.first, latLongs.last);
  }

  /// Returns true if the other point is equal or near this point. We use 0.00005 which is a distance of maximum 5.57m at the equator in each lat/lon direction
  static bool isNear(ILatLong me, ILatLong other) {
    if (me.latitude == other.latitude && me.longitude == other.longitude) return true;
    // now we have to rould the values so that we can compare them
    double latitude1 = roundToMicrodegreees(me.latitude);
    double latitude2 = roundToMicrodegreees(other.latitude);
    if ((latitude1 - latitude2).abs() > 0.00005) return false;
    double longitude1 = roundToMicrodegreees(me.longitude);
    double longitude2 = roundToMicrodegreees(other.longitude);
    if ((longitude1 - longitude2).abs() > 0.00005) return false;
    return true;
  }

  static double roundToMicrodegreees(double value) {
    return (value * CONVERSION_FACTOR).round() / CONVERSION_FACTOR;
  }

  /// Converts microdegrees to degrees.
  ///
  /// [coordinate] Coordinate in microdegrees (degrees × 10^6)
  /// Returns coordinate in degrees
  static double microdegreesToDegrees(int coordinate) {
    return coordinate / CONVERSION_FACTOR;
  }

  /// Converts degrees to microdegrees.
  ///
  /// [coordinate] Coordinate in degrees
  /// Returns coordinate in microdegrees (degrees × 10^6)
  static int degreesToMicrodegrees(double coordinate) {
    return (coordinate * CONVERSION_FACTOR).round();
  }

  /// Converts nanodegrees to degrees.
  ///
  /// [coordinate] Coordinate in nanodegrees (degrees × 10^9)
  /// Returns coordinate in degrees
  static double nanodegreesToDegrees(int coordinate) {
    return coordinate / NANO_CONVERSION_FACTOR;
  }

  /// Converts degrees to nanodegrees.
  ///
  /// [coordinate] Coordinate in degrees
  /// Returns coordinate in nanodegrees (degrees × 10^9)
  static int degreesToNanodegrees(double coordinate) {
    return (coordinate * NANO_CONVERSION_FACTOR).round();
  }

  /// Returns a point on the segment nearest to the specified point.
  /// <p>
  /// libGDX (Apache 2.0)
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

    for (var current in polygon) {
      if (previous != null) {
        final double x1 = previous.longitude;
        final double y1 = previous.latitude;
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
    }

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

  /// A convenience method to print a list of lat/long pairs
  static void printLatLongs(Way way) {
    for (var latlongs in way.latLongs) {
      List<String> results = [];
      String result = "";
      for (var latlong in latlongs) {
        result += "const LatLong(${(latlong.latitude).toStringAsFixed(6)},${(latlong.longitude).toStringAsFixed(6)}),";
        if (result.length > 250) {
          results.add(result);
          result = "";
        }
      }
      if (result.isNotEmpty) results.add(result);
      for (var action in results) {
        print("  $action");
      }
    }
  }

  static String printWaypaths(Iterable<Waypath> waypaths) {
    if (waypaths.length <= 20) {
      return "${waypaths.map((toElement) => "${toElement.length}").toList()}";
    }
    return "${waypaths.take(20).map((toElement) => "${toElement.length}").toList()} (${waypaths.length} items)";
  }

  /// Checks if a bounding box (boundary) intersects with a polygon.
  ///
  /// This method determines if a polygon would be visible within the given boundary
  /// by checking for various types of intersections:
  /// - Boundary completely inside polygon
  /// - Polygon completely inside boundary
  /// - Partial intersection (polygon edges cross boundary edges)
  ///
  /// [boundary] The rectangular boundary to test against
  /// [polygon] List of vertices defining the polygon
  /// Returns true if the polygon intersects with or is contained within the boundary
  static bool doesBoundaryIntersectPolygon(BoundingBox boundary, List<ILatLong> polygon) {
    if (polygon.length < 3) return false;

    // Get boundary corner points
    List<ILatLong> boundaryCorners = [
      LatLong(boundary.maxLatitude, boundary.minLongitude), // top-left
      LatLong(boundary.maxLatitude, boundary.maxLongitude), // top-right
      LatLong(boundary.minLatitude, boundary.maxLongitude), // bottom-right
      LatLong(boundary.minLatitude, boundary.minLongitude), // bottom-left
    ];

    // Check if boundary is completely inside polygon
    // If all boundary corners are inside the polygon, boundary is contained
    bool allCornersInside = true;
    for (ILatLong corner in boundaryCorners) {
      if (!isPointInPolygon(corner, polygon)) {
        allCornersInside = false;
        break;
      }
    }
    if (allCornersInside) return true;

    // Check if polygon is completely inside boundary
    // If all polygon vertices are inside the boundary, polygon is contained
    bool allVerticesInside = true;
    for (ILatLong vertex in polygon) {
      if (!boundary.containsLatLong(vertex)) {
        allVerticesInside = false;
        break;
      }
    }
    if (allVerticesInside) return true;

    // Check for edge intersections between polygon and boundary
    // Get boundary edges
    List<List<ILatLong>> boundaryEdges = [
      [boundaryCorners[0], boundaryCorners[1]], // top edge
      [boundaryCorners[1], boundaryCorners[2]], // right edge
      [boundaryCorners[2], boundaryCorners[3]], // bottom edge
      [boundaryCorners[3], boundaryCorners[0]], // left edge
    ];

    // Check each polygon edge against each boundary edge
    for (int i = 0; i < polygon.length; i++) {
      ILatLong polygonStart = polygon[i];
      ILatLong polygonEnd = polygon[(i + 1) % polygon.length];

      for (List<ILatLong> boundaryEdge in boundaryEdges) {
        if (doLinesIntersect(polygonStart, polygonEnd, boundaryEdge[0], boundaryEdge[1])) {
          return true;
        }
      }
    }

    // Check if any polygon vertex is inside the boundary (partial containment)
    for (ILatLong vertex in polygon) {
      if (boundary.containsLatLong(vertex)) {
        return true;
      }
    }

    // Check if any boundary corner is inside the polygon (partial containment)
    for (ILatLong corner in boundaryCorners) {
      if (isPointInPolygon(corner, polygon)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a bounding box is completely contained within a polygon.
  ///
  /// [boundary] The rectangular boundary to test
  /// [polygon] List of vertices defining the polygon
  /// Returns true if the entire boundary is inside the polygon
  static bool isBoundaryInsidePolygon(BoundingBox boundary, List<ILatLong> polygon) {
    if (polygon.length < 3) return false;

    // Get boundary corner points
    List<ILatLong> boundaryCorners = [
      LatLong(boundary.maxLatitude, boundary.minLongitude), // top-left
      LatLong(boundary.maxLatitude, boundary.maxLongitude), // top-right
      LatLong(boundary.minLatitude, boundary.maxLongitude), // bottom-right
      LatLong(boundary.minLatitude, boundary.minLongitude), // bottom-left
    ];

    // Check if all boundary corners are inside the polygon
    for (ILatLong corner in boundaryCorners) {
      if (!isPointInPolygon(corner, polygon)) {
        return false;
      }
    }

    return true;
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
