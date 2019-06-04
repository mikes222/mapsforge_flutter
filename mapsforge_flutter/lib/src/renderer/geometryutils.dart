import '../model/mappoint.dart';

class GeometryUtils {
  /**
   * Calculates the center of the minimum bounding rectangle for the given coordinates.
   *
   * @param coordinates the coordinates for which calculation should be done.
   * @return the center coordinates of the minimum bounding rectangle.
   */
  static Mappoint calculateCenterOfBoundingBox(List<Mappoint> coordinates) {
    double pointXMin = coordinates[0].x;
    double pointXMax = coordinates[0].x;
    double pointYMin = coordinates[0].y;
    double pointYMax = coordinates[0].y;

    for (Mappoint immutablePoint in coordinates) {
      if (immutablePoint.x < pointXMin) {
        pointXMin = immutablePoint.x;
      } else if (immutablePoint.x > pointXMax) {
        pointXMax = immutablePoint.x;
      }

      if (immutablePoint.y < pointYMin) {
        pointYMin = immutablePoint.y;
      } else if (immutablePoint.y > pointYMax) {
        pointYMax = immutablePoint.y;
      }
    }

    return new Mappoint(
        (pointXMin + pointXMax) / 2, (pointYMax + pointYMin) / 2);
  }
}
