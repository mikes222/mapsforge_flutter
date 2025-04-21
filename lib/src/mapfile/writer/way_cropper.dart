import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_simplify_filter.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';

class WayCropper {
  final _log = Logger('WayCropper');

  final double maxDeviationPixel;

  WayCropper({required this.maxDeviationPixel});

  Wayholder? cropWay(Wayholder wayholder, BoundingBox boundingBox, int maxZoomlevel) {
    List<Waypath> inner = wayholder.innerRead.map((test) => _optimizeWaypoints(test, boundingBox, maxZoomlevel)).toList()
      ..removeWhere((Waypath test) => test.isEmpty);
    List<Waypath> closedOuters = wayholder.closedOutersRead.map((test) => _optimizeWaypoints(test, boundingBox, maxZoomlevel)).toList()
      ..removeWhere((Waypath test) => test.isEmpty);
    List<Waypath> openOuters = wayholder.openOutersRead.map((test) => _optimizeWaypoints(test, boundingBox, maxZoomlevel)).toList()
      ..removeWhere((Waypath test) => test.isEmpty);

    if (inner.isEmpty && closedOuters.isEmpty && openOuters.isEmpty) return null;

    if (closedOuters.isEmpty && openOuters.isEmpty) {
      // only inner is set, move the first inner to the respective outer
      Waypath waypath = inner.first;
      inner.remove(waypath);
      if (waypath.isClosedWay())
        closedOuters.add(waypath);
      else
        openOuters.add(waypath);
    }

    // return a new wayholder instance
    return wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
  }

  /// Optimiert eine Liste von Wegpunkten, indem unnötige Punkte entfernt werden,
  /// während der Teil des Weges innerhalb der Tile-Boundary erhalten bleibt.
  ///
  /// @param waypoints Die Liste der Wegpunkte.
  /// @param tileBoundary Die Tile-Boundary (Bounding Box).
  /// @return Die optimierte Liste der Wegpunkte.
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
      return waypath;
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
    // if (path.length > 10) {
    //   path = _reduceOutside(waypath, tileBoundary);
    // }
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
      return Waypath(optimizedWaypoints);
    }
    path.forEach((waypoint) {
      bool isInside = tileBoundary.containsLatLong(waypoint);

      if (isInside) {
        if (previousWaypoint != null && !previousIsInside) {
          // Previous waypoint was outside, new waypoint is inside of the tile. Find the intersection point.
          final (intersectionPoint, direction) = _findIntersectionPoint(previousWaypoint!, waypoint, tileBoundary);
          if (firstEntryDirection == -1) firstEntryDirection = direction;
          lastEntryDirection = direction;
          _addCorners(lastExitDirection, lastEntryDirection, optimizedWaypoints, tileBoundary, path);
          optimizedWaypoints.add(intersectionPoint!);
        }
        optimizedWaypoints.add(waypoint);
      } else {
        if (previousWaypoint != null && previousIsInside) {
          // Previous waypoint was inside, the new waypoint is outside of the tile. We must find the intersection point.
          final (intersectionPoint, direction) = _findIntersectionPoint(previousWaypoint!, waypoint, tileBoundary);
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
          final (intersectionPoint, direction) = _findIntersectionPointOutside(previousWaypoint!, waypoint, tileBoundary);
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
    });

    if (!waypath.isClosedWay()) {
      // never touched the tile boundary
      if (optimizedWaypoints.isEmpty) return Waypath.empty();
      // original waypath was NOT closed, so we are done.
      if (optimizedWaypoints.length > 32767) {
        // many waypoints? simplify them.
        WaySimplifyFilter simplifyFilter = WaySimplifyFilter(maxZoomlevel, maxDeviationPixel);
        Waypath result = simplifyFilter.reduceWayEnsureMax(Waypath(optimizedWaypoints));
        return result;
      }
      return Waypath(optimizedWaypoints);
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
      return Waypath(optimizedWaypoints);
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
        Waypath result = simplifyFilter.reduceWayEnsureMax(Waypath(optimizedWaypoints));
        return result;
      }
      return Waypath(optimizedWaypoints);
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
      return Waypath(tempWaypoints);
    }
    // We have to close it the other way around
    _addCornersOtherWay(lastExitDirection, firstEntryDirection, optimizedWaypoints, tileBoundary);
    optimizedWaypoints.add(optimizedWaypoints.first);
    assert(optimizedWaypoints.length >= 3);
    assert(optimizedWaypoints.length <= 32767);
    return Waypath(optimizedWaypoints);
  }

  /// I want to reduce the nodes outside the boundary. Would be cool to remove a couple of nodes at once because all nodes in this slice are
  /// outside the given tile. Unfortunately this is not working for now.
  List<ILatLong> _reduceOutside(Waypath waypath, BoundingBox tileBoundary) {
    List<ILatLong> result = [];
    Queue<_QueueEntry> queue = Queue();
    List<ILatLong> points = waypath.path;
    bool addFirst = false;
    if (waypath.isClosedWay()) {
      queue.add(_QueueEntry(1, points.length - 2));
      addFirst = true;
    } else {
      queue.add(_QueueEntry(0, points.length - 1));
    }

    while (queue.isNotEmpty) {
      _QueueEntry current = queue.removeFirst();

      if (current.end == current.start + 1) {
        BoundingBox boundingBox = BoundingBox.from2(points[current.start], points[current.end]);
        if (tileBoundary.intersects(boundingBox)) {
          result.add(points[current.start]);
          result.add(points[current.end]);
        }
      } else {
        BoundingBox boundingBox = BoundingBox.fromLatLongs(points.slice(current.start, current.end + 1));
        if (tileBoundary.intersects(boundingBox)) {
          int middle = (current.start + current.end) ~/ 2;
          queue.addFirst(_QueueEntry(middle, current.end));
          queue.addFirst(_QueueEntry(current.start, middle));
        } else {
          // this is the magic. A portion of the way is outside the tile. We could remove 100s of nodes at once.
          if (current.end < points.length - 1) queue.addFirst(_QueueEntry(current.end, current.end + 1));
          if (current.start > 0) queue.addFirst(_QueueEntry(current.start - 1, current.start));
        }
      }
    }
    if (addFirst && result.isNotEmpty) {
      result.insert(0, waypath.path.first);
      result.add(waypath.path.first);
    }
    return result;
  }

  void _addCorners(int lastExitDirection, int newEntryDirection, List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary, List<ILatLong> waypoints) {
    switch (lastExitDirection) {
      case 0:
        // exit top (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 2:
            // entry bottom, left or right? This approach does NOT work in any circumstance but it should make the code a bit better
            if (LatLongUtils.isPointInPolygon(tileBoundary.getRightUpper(), waypoints) ||
                LatLongUtils.isPointInPolygon(tileBoundary.getRightLower(), waypoints)) {
              optimizedWaypoints.add(tileBoundary.getRightUpper());
              optimizedWaypoints.add(tileBoundary.getRightLower());
            } else {
              optimizedWaypoints.add(tileBoundary.getLeftUpper());
              optimizedWaypoints.add(tileBoundary.getLeftLower());
            }
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case -1:
            break;
        }
        break;
      case 1:
        // exit right (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 1:
            // entry right
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getRightLower());
            break;
          case 3:
            // entry left
            if (LatLongUtils.isPointInPolygon(tileBoundary.getRightUpper(), waypoints) ||
                LatLongUtils.isPointInPolygon(tileBoundary.getLeftUpper(), waypoints)) {
              optimizedWaypoints.add(tileBoundary.getRightUpper());
              optimizedWaypoints.add(tileBoundary.getLeftUpper());
            } else {
              optimizedWaypoints.add(tileBoundary.getRightLower());
              optimizedWaypoints.add(tileBoundary.getLeftLower());
            }
            break;
          case -1:
            break;
        }
        break;
      case 2:
        // exit bottom (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            if (LatLongUtils.isPointInPolygon(tileBoundary.getRightLower(), waypoints) ||
                LatLongUtils.isPointInPolygon(tileBoundary.getRightUpper(), waypoints)) {
              optimizedWaypoints.add(tileBoundary.getRightLower());
              optimizedWaypoints.add(tileBoundary.getRightUpper());
            } else {
              optimizedWaypoints.add(tileBoundary.getLeftLower());
              optimizedWaypoints.add(tileBoundary.getLeftUpper());
            }
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getRightLower());
            break;
          case 2:
            // entry bottom
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case -1:
            break;
        }
        break;
      case 3:
        // exit left (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 1:
            // entry right
            if (LatLongUtils.isPointInPolygon(tileBoundary.getLeftLower(), waypoints) ||
                LatLongUtils.isPointInPolygon(tileBoundary.getRightLower(), waypoints)) {
              optimizedWaypoints.add(tileBoundary.getLeftLower());
              optimizedWaypoints.add(tileBoundary.getRightLower());
            } else {
              optimizedWaypoints.add(tileBoundary.getLeftUpper());
              optimizedWaypoints.add(tileBoundary.getRightUpper());
            }
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case 3:
            // entry left
            break;
          case -1:
            break;
        }
        break;
      case -1:
    }
  }

  void _addCornersOtherWay(int lastExitDirection, int newEntryDirection, List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary) {
    switch (lastExitDirection) {
      case 0:
        // exit top (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case -1:
            break;
        }
        break;
      case 1:
        // exit right (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case -1:
            break;
        }
        break;
      case 2:
        // exit bottom (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case -1:
            break;
        }
        break;
      case 3:
        // exit left (from exit to entry)
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case -1:
            break;
        }
        break;
      case -1:
    }
  }

  /// Findet den Schnittpunkt eines Liniensegments mit den Kanten der Tile-Boundary.
  ///
  /// @param start Der Startpunkt des Liniensegments.
  /// @param end Der Endpunkt des Liniensegments.
  /// @param tileBoundary Die Tile-Boundary (Bounding Box).
  /// @return Der Schnittpunkt als ILatLong oder null, wenn kein Schnittpunkt gefunden wurde.
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

  /// Find the intersection point with the tile where the intersectionpoint is
  /// the nearest to the start assuming that both points are outside the tile.
  ///
  /// @param start Der Startpunkt des Liniensegments.
  /// @param end Der Endpunkt des Liniensegments.
  /// @param tileBoundary Die Tile-Boundary (Bounding Box).
  /// @return Der Schnittpunkt als ILatLong oder null, wenn kein Schnittpunkt gefunden wurde.
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
