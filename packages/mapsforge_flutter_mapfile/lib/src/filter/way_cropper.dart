import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_simplify_filter.dart';

/// A utility class for cropping and simplifying way geometries to fit within a
/// given bounding box (typically a map tile).
///
/// This is essential for rendering performance, as it reduces the number of
/// vertices that need to be processed and drawn, especially for large polygons
/// or long ways that only partially intersect a tile.
class WayCropper {
  final double maxDeviationPixel;

  const WayCropper({required this.maxDeviationPixel});

  /// Crops the ways within a [wayholder] to the given [boundingBox].
  ///
  /// This method processes the inner and outer ways of the wayholder, optimizing
  /// them to include only the segments that are visible within the bounding box.
  /// It also simplifies the geometry if it contains too many points.
  ///
  /// Returns a new [Wayholder] with the cropped ways, or `null` if no part of
  /// the way is within the bounding box.
  Wayholder? cropWay(Wayholder wayholder, BoundingBox boundingBox, int maxZoomlevel) {
    List<Waypath> inner = wayholder.innerRead.map((test) => _optimizeWaypoints(test, boundingBox, maxZoomlevel)).toList()
      ..removeWhere((Waypath test) => test.isEmpty);

    List<Waypath> closedOuters = [];
    for (var test in wayholder.closedOutersRead) {
      Waypath result = _optimizeWaypoints(test, boundingBox, maxZoomlevel);
      if (result.isNotEmpty) {
        assert(result.isClosedWay());
        closedOuters.add(result);
      }
    }

    List<Waypath> openOuters = wayholder.openOutersRead.map((test) => _optimizeWaypoints(test, boundingBox, maxZoomlevel)).toList()
      ..removeWhere((Waypath test) => test.isEmpty);

    if (inner.isEmpty && closedOuters.isEmpty && openOuters.isEmpty) return null;

    // return a new wayholder instance
    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    result.moveInnerToOuter();
    return result;
  }

  /// An alternative cropping method that reduces the nodes of a way that are
  /// outside the given [boundingBox].
  ///
  /// This is a less aggressive optimization than [cropWay] and is used in
  /// specific scenarios.
  Wayholder? cropOutsideWay(Wayholder wayholder, BoundingBox boundingBox) {
    List<Waypath> inner = [];
    for (var test in wayholder.innerRead) {
      Waypath result = _reduceOutside(test, boundingBox);
      if (result.isNotEmpty) {
        inner.add(result);
      }
    }

    List<Waypath> closedOuters = [];
    for (var test in wayholder.closedOutersRead) {
      assert(test.isClosedWay(), "test is not a closed way $test ${test.path}");
      Waypath result = _reduceOutside(test, boundingBox);
      if (result.isNotEmpty) {
        assert(result.isClosedWay(), "result is not a closed way $result ${test.path} ${result.path}");
        closedOuters.add(result);
      }
    }

    List<Waypath> openOuters = [];
    for (var test in wayholder.openOutersRead) {
      assert(!test.isClosedWay(), "test is not an open way $test ${test.path}");
      Waypath result = _reduceOutside(test, boundingBox);
      if (result.isNotEmpty) {
        assert(!result.isClosedWay(), "result is not an open way $result ${test.path} ${result.path}");
        openOuters.add(result);
      }
    }

    if (inner.isEmpty && closedOuters.isEmpty && openOuters.isEmpty) return null;

    // return a new wayholder instance
    Wayholder? result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    result.moveInnerToOuter();
    return result;
  }

  /// Optimizes a way by cropping it to the tile boundary and simplifying it.
  ///
  /// This is the core method for processing a single way. It handles cases where
  /// the way is completely inside, completely outside, or intersecting the tile.
  /// For intersecting ways, it calculates the intersection points and adds the
  /// necessary corner points of the tile boundary to create a closed polygon
  /// that can be filled.
  Waypath _optimizeWaypoints(Waypath waypath, BoundingBox tileBoundary, int maxZoomlevel) {
    if (waypath.isEmpty) return Waypath.empty();

    BoundingBox wayBoundingBox = waypath.boundingBox;
    // all points inside the tile boundary
    if (tileBoundary.containsBoundingBox(wayBoundingBox)) {
      if (waypath.length > 32767) {
        // many waypoints? simplify them.
        WaySimplifyFilter simplifyFilter = WaySimplifyFilter(maxZoomlevel, maxDeviationPixel);
        Waypath result = simplifyFilter.reduceWayEnsureMax(waypath);
        //_log.info("${waypath.length} are too many points for zoomlevel $maxZoomlevel for tile $tileBoundary, reduced to ${result.length}");
        return result;
      }
      return waypath.clone();
    }

    // no intersection, ignore these points
    if (!tileBoundary.intersects(wayBoundingBox)) return Waypath.empty();

    List<ILatLong> optimizedWaypoints = [];
    ILatLong? previousWaypoint;
    bool previousIsInside = false;
    var firstEntryDirection = -1;
    var firstExitDirection = -1;
    var lastEntryDirection = -1;
    var lastExitDirection = -1;

    List<ILatLong> path = waypath.path;
    if (path.length > 20) {
      path = _reduceOutside(waypath, tileBoundary).path;
    }
    if (path.isEmpty) {
      // no points inside the tile boundary
      if (!waypath.isClosedWay()) {
        // original path is NOT a closed way so we can return an empty path
        return Waypath.empty();
      }
      // original is a closed way but never intersected with the tile, that means
      // it is surrounding the tile. This is different to the original since we create areas for each tile. This is also the reason why
      // we do not support zoomlevels smaller than base-zoomlevel per subfile. In such cases the system combines for example 4 tiles to one
      // and we would draw 4 squares (with strokes) whereas we should only draw the fill and no strokes.
      // Step 1: Find out if the center of the tile is inside or outside of the original way
      bool isInside = LatLongUtils.isPointInPolygon(tileBoundary.getCenterPoint(), waypath.path);
      if (!isInside) {
        // no intersection, ignore these points
        return Waypath.empty();
      }
      optimizedWaypoints.add(tileBoundary.getLeftUpper());
      optimizedWaypoints.add(tileBoundary.getRightUpper());
      optimizedWaypoints.add(tileBoundary.getRightLower());
      optimizedWaypoints.add(tileBoundary.getLeftLower());
      optimizedWaypoints.add(tileBoundary.getLeftUpper());
      return Waypath(path: optimizedWaypoints);
    }
    for (var waypoint in path) {
      bool isInside = tileBoundary.containsLatLong(waypoint);

      if (isInside) {
        if (previousWaypoint != null && !previousIsInside) {
          // Previous waypoint was outside, new waypoint is inside of the tile. Find the intersection point.
          final (intersectionPoint, direction) = _findIntersectionPoint(previousWaypoint, waypoint, tileBoundary);
          if (firstEntryDirection == -1) firstEntryDirection = direction;
          lastEntryDirection = direction;
          _addCorners(lastExitDirection, lastEntryDirection, optimizedWaypoints, tileBoundary, path);
          optimizedWaypoints.add(intersectionPoint!);
        }
        optimizedWaypoints.add(waypoint);
      } else {
        if (previousWaypoint != null && previousIsInside) {
          // Previous waypoint was inside, the new waypoint is outside of the tile. We must find the intersection point.
          final (intersectionPoint, direction) = _findIntersectionPoint(previousWaypoint, waypoint, tileBoundary);
          optimizedWaypoints.add(intersectionPoint!);
          if (firstExitDirection == -1) firstExitDirection = direction;
          lastExitDirection = direction;
        } else if (previousWaypoint != null && !previousIsInside) {
          // both are outside but they may intersect the tile
          // BoundingBox intersect = BoundingBox.from2(previousWaypoint!, waypoint);
          // if (!tileBoundary.intersects(intersect)) {
          //   // no intersection, this should be a quick test
          //   return;
          // }
          final (intersectionPoint, direction) = _findIntersectionPointOutside(previousWaypoint, waypoint, tileBoundary);
          if (intersectionPoint != null) {
            // yes, they intersect (twice)
            if (firstEntryDirection == -1) firstEntryDirection = direction;
            lastEntryDirection = direction;
            _addCorners(lastExitDirection, lastEntryDirection, optimizedWaypoints, tileBoundary, path);
            optimizedWaypoints.add(intersectionPoint);
            // and now find the exit point. Search in opposite direction to find
            // the exit point nearest to the current waypoint
            final (exitIntersectionPoint, exitDirection) = _findIntersectionPointOutside(waypoint, intersectionPoint, tileBoundary);
            optimizedWaypoints.add(exitIntersectionPoint!);
            if (firstExitDirection == -1) firstExitDirection = exitDirection;
            lastExitDirection = exitDirection;
          }
        }
      }

      previousWaypoint = waypoint;
      previousIsInside = isInside;
    }

    if (!waypath.isClosedWay()) {
      // never touched the tile boundary
      if (optimizedWaypoints.isEmpty) return Waypath.empty();
      // original waypath was NOT closed, so we are done.
      if (optimizedWaypoints.length > 32767) {
        // many waypoints? simplify them.
        WaySimplifyFilter simplifyFilter = WaySimplifyFilter(maxZoomlevel, maxDeviationPixel);
        Waypath result = simplifyFilter.reduceWayEnsureMax(Waypath(path: optimizedWaypoints));
        return result;
      }
      return Waypath(path: optimizedWaypoints);
    }
    // Step 1: Find out if the center of the tile is inside or outside of the original way
    bool isInside = LatLongUtils.isPointInPolygon(tileBoundary.getCenterPoint(), waypath.path);
    if (optimizedWaypoints.isEmpty && !isInside) {
      // no intersection, ignore these points
      return Waypath.empty();
    }
    if (optimizedWaypoints.isEmpty) {
      // original is a closed way but never intersected with the tile, that means
      // it is surrounding the tile. This is different to the original since we create areas for each tile. This is also the reason why
      // we do not support zoomlevels smaller than base-zoomlevel per subfile. In such cases the system combines for example 4 tiles to one
      // and we would draw 4 squares (with strokes) whereas we should only draw the fill and no strokes.
      optimizedWaypoints.add(tileBoundary.getLeftUpper());
      optimizedWaypoints.add(tileBoundary.getRightUpper());
      optimizedWaypoints.add(tileBoundary.getRightLower());
      optimizedWaypoints.add(tileBoundary.getLeftLower());
      optimizedWaypoints.add(tileBoundary.getLeftUpper());
      return Waypath(path: optimizedWaypoints);
    }
    if (LatLongUtils.isClosedWay(optimizedWaypoints)) {
      if (optimizedWaypoints.first != optimizedWaypoints.last) {
        // make sure the way is closed even if first and last points are a tiny bit apart
        optimizedWaypoints.add(optimizedWaypoints.first);
      }
      // everything ok
      assert(optimizedWaypoints.length >= 3);

      if (optimizedWaypoints.length > 32767) {
        WaySimplifyFilter simplifyFilter = WaySimplifyFilter(maxZoomlevel, maxDeviationPixel);
        Waypath result = simplifyFilter.reduceWayEnsureMax(Waypath(path: optimizedWaypoints));
        return result;
      }
      return Waypath(path: optimizedWaypoints);
    }
    // if start and end would be inside the tile we would have a closed way. So both must be outside
    // find how we should close the way:
    // Step 2: Temporary close the way and find out if the center of the tile is inside or outside of the new way
    List<ILatLong> tempWaypoints = List.from(optimizedWaypoints);
    _addCorners(lastExitDirection, firstEntryDirection, tempWaypoints, tileBoundary, path);
    // close the temporary way
    tempWaypoints.add(tempWaypoints.first);
    bool isInsideNew = LatLongUtils.isPointInPolygon(tileBoundary.getCenterPoint(), tempWaypoints);
    if (isInside == isInsideNew) {
      // perfect, both are inside or outside
      assert(tempWaypoints.length >= 3);
      assert(tempWaypoints.length <= 32767);
      return Waypath(path: tempWaypoints);
    }
    // We have to close it the other way around
    _addCornersOtherWay(lastExitDirection, firstEntryDirection, optimizedWaypoints, tileBoundary);
    optimizedWaypoints.add(optimizedWaypoints.first);
    assert(optimizedWaypoints.length >= 3);
    assert(optimizedWaypoints.length <= 32767);
    return Waypath(path: optimizedWaypoints);
  }

  /// Reduces the number of nodes in a way that are outside the given [tileBoundary].
  ///
  /// This method uses a queue-based approach to recursively subdivide the way
  /// and discard segments that do not intersect with the tile boundary. This can
  /// significantly reduce the number of points for long ways that are mostly
  /// outside the tile.
  Waypath _reduceOutside(Waypath waypath, BoundingBox tileBoundary) {
    if (tileBoundary.containsBoundingBox(waypath.boundingBox)) return waypath;
    List<ILatLong> result = [];
    Queue<_QueueEntry> queue = Queue();
    List<ILatLong> points = waypath.path;
    queue.add(_QueueEntry(0, points.length - 1));

    while (queue.isNotEmpty) {
      _QueueEntry current = queue.removeFirst();

      if (current.end == current.start + 1) {
        // this section consists of only 2 points (1 line). Both endpoints may be necessary even if the line does not intersect. This is for example if
        // one of these endpoints is the first endpoint outside of the tile.
        //        BoundingBox boundingBox = BoundingBox.from2(points[current.start], points[current.end]);
        result.add(points[current.start]);
        result.add(points[current.end]);
      } else {
        BoundingBox boundingBox = BoundingBox.fromLatLongs(points.slice(current.start, current.end + 1));
        if (tileBoundary.intersects(boundingBox)) {
          int middle = (current.start + current.end) ~/ 2;
          queue.addFirst(_QueueEntry(middle, current.end));
          queue.addFirst(_QueueEntry(current.start, middle));
        } else {
          // this is the magic. A portion of the way is outside the tile. We could remove 100s of nodes at once.
          result.add(points[current.start]);
          result.add(points[current.end]);
        }
      }
    }
    if (waypath.isClosedWay() && result.length < 3) return Waypath.empty();
    return Waypath(path: result);
  }

  void _addCorners(int lastExitDirection, int newEntryDirection, List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary, List<ILatLong> waypoints) {
    // we had no exit from our tile, so we do not need to add any corners
    if (lastExitDirection == -1) return;
    // always assume last exit on the top. We rotate the corners if this is not the case.
    int entryDiffDirection = (newEntryDirection - lastExitDirection + 4) % 4;
    switch (entryDiffDirection) {
      case 0:
        // entry top
        break;
      case 1:
        // entry right
        optimizedWaypoints.add(tileBoundary.getRightUpperRotate(lastExitDirection));
        break;
      case 2:
        // entry bottom, left or right? This approach does NOT work in any circumstance but it should make the code a bit better
        if (LatLongUtils.isPointInPolygon(tileBoundary.getRightUpperRotate(lastExitDirection), waypoints) ||
            LatLongUtils.isPointInPolygon(tileBoundary.getRightLowerRotate(lastExitDirection), waypoints)) {
          optimizedWaypoints.add(tileBoundary.getRightUpperRotate(lastExitDirection));
          optimizedWaypoints.add(tileBoundary.getRightLowerRotate(lastExitDirection));
        } else {
          optimizedWaypoints.add(tileBoundary.getLeftUpperRotate(lastExitDirection));
          optimizedWaypoints.add(tileBoundary.getLeftLowerRotate(lastExitDirection));
        }
        break;
      case 3:
        // entry left
        optimizedWaypoints.add(tileBoundary.getLeftUpperRotate(lastExitDirection));
        break;
      case -1:
        break;
    }
  }

  void _addCornersOtherWay(int lastExitDirection, int newEntryDirection, List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary) {
    // we had no exit from our tile, so we do not need to add any corners
    if (lastExitDirection == -1) return;
    int entryDiffDirection = (newEntryDirection - lastExitDirection + 4) % 4;
    switch (entryDiffDirection) {
      case 0:
        // entry top
        optimizedWaypoints.add(tileBoundary.getRightUpperRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getRightLowerRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getLeftLowerRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getLeftUpperRotate(lastExitDirection));
        break;
      case 1:
        // entry right
        optimizedWaypoints.add(tileBoundary.getLeftUpperRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getLeftLowerRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getRightLowerRotate(lastExitDirection));
        break;
      case 2:
        // entry bottom
        optimizedWaypoints.add(tileBoundary.getLeftUpperRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getLeftLowerRotate(lastExitDirection));
        break;
      case 3:
        // entry left
        optimizedWaypoints.add(tileBoundary.getRightUpperRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getRightLowerRotate(lastExitDirection));
        optimizedWaypoints.add(tileBoundary.getLeftLowerRotate(lastExitDirection));
        break;
      case -1:
        break;
    }
  }

  /// Finds the intersection point of a line segment with the edges of the tile boundary.
  ///
  /// Assumes one point is inside and one is outside the boundary.
  /// Returns the intersection point and the direction of the edge that was hit
  /// (0=top, 1=right, 2=bottom, 3=left).
  (ILatLong?, int) _findIntersectionPoint(ILatLong start, ILatLong end, BoundingBox tileBoundary) {
    final topLeft = LatLong(tileBoundary.maxLatitude, tileBoundary.minLongitude);
    final topRight = LatLong(tileBoundary.maxLatitude, tileBoundary.maxLongitude);
    final bottomRight = LatLong(tileBoundary.minLatitude, tileBoundary.maxLongitude);
    final bottomLeft = LatLong(tileBoundary.minLatitude, tileBoundary.minLongitude);

    // Prüfe jeden Rand des Rechtecks auf Schnittpunkte

    ILatLong? intersection = LatLongUtils.getLineIntersectionHorizontal(start, end, topLeft, topRight);
    if (intersection != null) return (intersection, 0);

    intersection = LatLongUtils.getLineIntersectionVertical(start, end, topRight, bottomRight);
    if (intersection != null) return (intersection, 1);

    intersection = LatLongUtils.getLineIntersectionHorizontal(start, end, bottomRight, bottomLeft);
    if (intersection != null) return (intersection, 2);

    intersection = LatLongUtils.getLineIntersectionVertical(start, end, bottomLeft, topLeft);
    if (intersection != null) return (intersection, 3);

    return (null, -1);
  }

  /// Finds the intersection point of a line segment with the tile boundary, assuming
  /// both start and end points are outside the tile.
  ///
  /// This is used to detect cases where a way passes through a tile without having
  /// any of its nodes inside the tile.
  /// Returns the intersection point and the direction of the edge that was hit.
  (ILatLong?, int) _findIntersectionPointOutside(ILatLong start, ILatLong end, BoundingBox tileBoundary) {
    final topLeft = LatLong(tileBoundary.maxLatitude, tileBoundary.minLongitude);
    final topRight = LatLong(tileBoundary.maxLatitude, tileBoundary.maxLongitude);
    final bottomRight = LatLong(tileBoundary.minLatitude, tileBoundary.maxLongitude);
    final bottomLeft = LatLong(tileBoundary.minLatitude, tileBoundary.minLongitude);

    // Prüfe jeden Rand des Rechtecks auf Schnittpunkte

    if (start.latitude > end.latitude) {
      ILatLong? intersection = LatLongUtils.getLineIntersectionHorizontal(start, end, topLeft, topRight);
      if (intersection != null) return (intersection, 0);

      return _checkLeftRight(start, end, topLeft, topRight, bottomRight, bottomLeft);
    } else {
      ILatLong? intersection = LatLongUtils.getLineIntersectionHorizontal(start, end, bottomRight, bottomLeft);
      if (intersection != null) return (intersection, 2);

      return _checkLeftRight(start, end, topLeft, topRight, bottomRight, bottomLeft);
    }
  }

  (ILatLong?, int) _checkLeftRight(ILatLong start, ILatLong end, ILatLong topLeft, ILatLong topRight, ILatLong bottomRight, ILatLong bottomLeft) {
    if (start.longitude > end.longitude) {
      ILatLong? intersection = LatLongUtils.getLineIntersectionVertical(start, end, topRight, bottomRight);
      if (intersection != null) return (intersection, 1);
    } else {
      ILatLong? intersection1 = LatLongUtils.getLineIntersectionVertical(start, end, bottomLeft, topLeft);
      if (intersection1 != null) return (intersection1, 3);
    }

    return (null, -1);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _QueueEntry {
  final int start;

  final int end;

  _QueueEntry(this.start, this.end);
}
