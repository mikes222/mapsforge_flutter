import '../model/linesegment.dart';
import '../model/linestring.dart';

class WayDecorator {
  static final double MAX_LABEL_CORNER_ANGLE = 10;

  static LineString reducePathForText(LineString fullPath, double textWidth) {
    LineString result = LineString();
    LineString path = LineString();
    LineString longestPath = LineString();
    for (LineSegment segment in fullPath.segments) {
      if (segment.end == segment.start) {
        continue;
      }
      if (segment.length() > textWidth) {
        // we found a segment which is long enough so use this instead of all the small segments before
        result.segments.add(segment);
        path = LineString();
        // todo split very long segments to several small segments and draw the text in each
        continue;
      }
      if (path.segments.isNotEmpty) {
        double cornerAngle = path.segments.last.angleTo(segment);
        if ((cornerAngle).abs() > MAX_LABEL_CORNER_ANGLE) {
          if (longestPath.length() < path.length()) longestPath = path;
          path = LineString();
          continue;
        }
      }
      path.segments.add(segment);
      if (path.length() > textWidth &&
          path.segments.first.start != path.segments.last.end) {
        result.segments.add(
            LineSegment(path.segments.first.start, path.segments.last.end));
        path = LineString();
      }
    }
    if (result.segments.isEmpty &&
        longestPath.segments.isNotEmpty &&
        longestPath.length() > textWidth * 2 / 3) {
      // we do not have a sufficient length for the text but the remaining path is 2/3 of what we need so use it
      if (longestPath.segments.first.start != longestPath.segments.last.end)
        result.segments.add(LineSegment(
            longestPath.segments.first.start, longestPath.segments.last.end));
    }
    return result;
  }
}
