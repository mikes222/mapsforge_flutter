import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';

import '../../../datastore.dart';

class WayCropper {
  Wayholder cropWay(Wayholder wayholder, BoundingBox boundingBox) {
    List<List<ILatLong>> newLatLongs = [];
    wayholder.way.latLongs.forEach((test) {
      List<ILatLong> toAdd = _optimizeWaypoints(test, boundingBox);
      if (toAdd.length >= 2) newLatLongs.add(toAdd);
    });
    Way way = Way(wayholder.way.layer, wayholder.way.tags, newLatLongs,
        wayholder.way.labelPosition);
    newLatLongs = [];
    wayholder.otherOuters.forEach((test) {
      List<ILatLong> toAdd = _optimizeWaypoints(test, boundingBox);
      if (toAdd.length >= 2) newLatLongs.add(toAdd);
    });
    // return a new wayholder instance
    return wayholder.cloneWith(way: way, otherOuters: newLatLongs);
  }

  /// Optimiert eine Liste von Wegpunkten, indem unnötige Punkte entfernt werden,
  /// während der Teil des Weges innerhalb der Tile-Boundary erhalten bleibt.
  ///
  /// @param waypoints Die Liste der Wegpunkte.
  /// @param tileBoundary Die Tile-Boundary (Bounding Box).
  /// @return Die optimierte Liste der Wegpunkte.
  List<ILatLong> _optimizeWaypoints(
      List<ILatLong> waypoints, BoundingBox tileBoundary) {
    if (waypoints.isEmpty) return [];

    BoundingBox wayBoundingBox = BoundingBox.fromLatLongs(waypoints);
    // all points inside the tile boundary
    if (tileBoundary.containsBoundingBox(wayBoundingBox)) return waypoints;

    // no intersection, ignore these points
    if (!tileBoundary.intersects(wayBoundingBox)) return [];

    List<ILatLong> optimizedWaypoints = [];
    ILatLong? previousWaypoint;
    bool previousIsInside = false;
    var firstEntryDirection = -1;
    var lastExitDirection = -1;

    waypoints.forEachIndexed((index, waypoint) {
      bool isInside = tileBoundary.containsLatLong(waypoint);

      if (isInside) {
        if (previousWaypoint != null && !previousIsInside) {
          // Previous waypoint was outside, new waypoint is inside of the tile. Find the intersection point.
          final (intersectionPoint, direction) =
              _findIntersectionPoint(previousWaypoint!, waypoint, tileBoundary);
          _addCorners(
              lastExitDirection, direction, optimizedWaypoints, tileBoundary);
          optimizedWaypoints.add(intersectionPoint!);
          if (firstEntryDirection == -1) firstEntryDirection = direction;
        }
        optimizedWaypoints.add(waypoint);
      } else {
        if (previousWaypoint != null && previousIsInside) {
          // Previous waypoint was inside, the new waypoint is outside of the tile. We must find the intersection point.
          final (intersectionPoint, direction) =
              _findIntersectionPoint(previousWaypoint!, waypoint, tileBoundary);
          optimizedWaypoints.add(intersectionPoint!);
          lastExitDirection = direction;
        } else if (previousWaypoint != null && !previousIsInside) {
          // both are outside but they may intersect the tile
          final (intersectionPoint, direction) = _findIntersectionPointOutside(
              previousWaypoint!, waypoint, tileBoundary);
          if (intersectionPoint != null) {
            // yes, they intersect (twice)
            if (firstEntryDirection == -1) firstEntryDirection = direction;
            _addCorners(
                lastExitDirection, direction, optimizedWaypoints, tileBoundary);
            optimizedWaypoints.add(intersectionPoint);
            // and now find the exit point. Search in opposite direction to find
            // the exit point nearest to the current waypoint
            final (exitIntersectionPoint, exitDirection) =
                _findIntersectionPointOutside(
                    waypoint, intersectionPoint, tileBoundary);
            optimizedWaypoints.add(exitIntersectionPoint!);
            lastExitDirection = exitDirection;
          }
        }
      }

      previousWaypoint = waypoint;
      previousIsInside = isInside;
    });

    // Check if it is a closed way and the new way is not closed
    if (LatLongUtils.isClosedWay(waypoints)) {
      // Step 1: Find out if the center of the tile is inside or outside of the original way
      bool isInside = LatLongUtils.isPointInPolygon(
          tileBoundary.getCenterPoint(), waypoints);
      if (optimizedWaypoints.isEmpty && !isInside) {
        // no intersection, ignore these points
        return [];
      }
      if (optimizedWaypoints.isEmpty) {
        // original is a closed way but never intersected with the tile, that means
        // it is surrounding us
        optimizedWaypoints.add(tileBoundary.getLeftUpper());
        optimizedWaypoints.add(tileBoundary.getRightUpper());
        optimizedWaypoints.add(tileBoundary.getRightLower());
        optimizedWaypoints.add(tileBoundary.getLeftLower());
        optimizedWaypoints.add(tileBoundary.getLeftUpper());
        return optimizedWaypoints;
      }
      if (LatLongUtils.isClosedWay(optimizedWaypoints)) {
        // everything ok
        return optimizedWaypoints;
      }
      // find how we should close the way:
      // Step 2: Temporary close the way and find out if the center of the tile is inside or outside of the new way
      List<ILatLong> tempWaypoints = List.from(optimizedWaypoints);
      _addCorners(
          lastExitDirection, firstEntryDirection, tempWaypoints, tileBoundary);
      tempWaypoints.add(tempWaypoints.first);
      bool isInsideNew = LatLongUtils.isPointInPolygon(
          tileBoundary.getCenterPoint(), tempWaypoints);
      if (isInside == isInsideNew) {
        // perfect, both are inside or outside
        return tempWaypoints;
      }
      // We have to close it the other way around
      _addCornersOtherWay(lastExitDirection, firstEntryDirection,
          optimizedWaypoints, tileBoundary);
      optimizedWaypoints.add(optimizedWaypoints.first);
      return optimizedWaypoints;
    }
    return optimizedWaypoints;
  }

  void _addCorners(int lastExitDirection, int newEntryDirection,
      List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary) {
    switch (lastExitDirection) {
      case 0:
        // exit top
        switch (newEntryDirection) {
          case 0:
            // entry top
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getRightLower());
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
        // exit right
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
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case -1:
            break;
        }
        break;
      case 2:
        // exit bottom
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
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
        // exit left
        switch (newEntryDirection) {
          case 0:
            // entry top
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 1:
            // entry right
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getRightLower());
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

  void _addCornersOtherWay(int lastExitDirection, int newEntryDirection,
      List<ILatLong> optimizedWaypoints, BoundingBox tileBoundary) {
    switch (lastExitDirection) {
      case 0:
        // exit top
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
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            break;
          case 2:
            // entry bottom
            optimizedWaypoints.add(tileBoundary.getLeftUpper());
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            break;
          case 3:
            // entry left
            optimizedWaypoints.add(tileBoundary.getLeftLower());
            optimizedWaypoints.add(tileBoundary.getRightLower());
            optimizedWaypoints.add(tileBoundary.getRightUpper());
            break;
          case -1:
            break;
        }
        break;
      case 1:
        // exit right
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
        // exit bottom
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
        // exit left
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
  (ILatLong?, int) _findIntersectionPoint(
      ILatLong start, ILatLong end, BoundingBox tileBoundary) {
    final topLeft =
        LatLong(tileBoundary.maxLatitude, tileBoundary.minLongitude);
    final topRight =
        LatLong(tileBoundary.maxLatitude, tileBoundary.maxLongitude);
    final bottomRight =
        LatLong(tileBoundary.minLatitude, tileBoundary.maxLongitude);
    final bottomLeft =
        LatLong(tileBoundary.minLatitude, tileBoundary.minLongitude);

    // Prüfe jeden Rand des Rechtecks auf Schnittpunkte

    ILatLong? intersection =
        LatLongUtils.getLineIntersection(start, end, topLeft, topRight);
    if (intersection != null) return (intersection, 0);

    intersection =
        LatLongUtils.getLineIntersection(start, end, topRight, bottomRight);
    if (intersection != null) return (intersection, 1);

    intersection =
        LatLongUtils.getLineIntersection(start, end, bottomRight, bottomLeft);
    if (intersection != null) return (intersection, 2);

    intersection =
        LatLongUtils.getLineIntersection(start, end, bottomLeft, topLeft);
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
  (ILatLong?, int) _findIntersectionPointOutside(
      ILatLong start, ILatLong end, BoundingBox tileBoundary) {
    final topLeft =
        LatLong(tileBoundary.maxLatitude, tileBoundary.minLongitude);
    final topRight =
        LatLong(tileBoundary.maxLatitude, tileBoundary.maxLongitude);
    final bottomRight =
        LatLong(tileBoundary.minLatitude, tileBoundary.maxLongitude);
    final bottomLeft =
        LatLong(tileBoundary.minLatitude, tileBoundary.minLongitude);

    // Prüfe jeden Rand des Rechtecks auf Schnittpunkte

    if (start.latitude > end.latitude) {
      ILatLong? intersection =
          LatLongUtils.getLineIntersection(start, end, topLeft, topRight);
      if (intersection != null) return (intersection, 0);

      return _checkLeftRight(
          start, end, topLeft, topRight, bottomRight, bottomLeft);
    } else {
      ILatLong? intersection =
          LatLongUtils.getLineIntersection(start, end, bottomRight, bottomLeft);
      if (intersection != null) return (intersection, 2);

      return _checkLeftRight(
          start, end, topLeft, topRight, bottomRight, bottomLeft);
    }

    return (null, -1);
  }

  (ILatLong?, int) _checkLeftRight(
      ILatLong start,
      ILatLong end,
      ILatLong topLeft,
      ILatLong topRight,
      ILatLong bottomRight,
      ILatLong bottomLeft) {
    if (start.longitude > end.longitude) {
      ILatLong? intersection =
          LatLongUtils.getLineIntersection(start, end, topRight, bottomRight);
      if (intersection != null) return (intersection, 1);
    } else {
      ILatLong? intersection1 =
          LatLongUtils.getLineIntersection(start, end, bottomLeft, topLeft);
      if (intersection1 != null) return (intersection1, 3);
    }

    return (null, -1);
  }
}
