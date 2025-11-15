import 'dart:math';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';

class PathHelper {
  static final _log = Logger('PathHelper');

  static List<Offsets> calculateDashes(List<Pointinfo> pointinfos, List<double> dasharray) {
    List<Offsets> dashed = [];
    // determines if we should draw a line or leave it open
    int dashIdx = 0;
    double dashLength = dasharray[dashIdx];
    Offset? startOffset;
    for (var pointinfo in pointinfos) {
      if (pointinfo.start) {
        dashIdx = 0;
        dashLength = dasharray[dashIdx];
        startOffset = pointinfo.offset;
        continue;
      }
      if (startOffset == null) {
        _log.warning("Startoffset is null for dash $dashed and points $pointinfos");
        startOffset = pointinfo.offset;
        continue;
      }
      DirectionVector directionVector = DirectionVector.get(startOffset, pointinfo.offset);
      while (directionVector.length > 0) {
        if (dashLength == 0) {
          ++dashIdx;
          if (dashIdx == dasharray.length) dashIdx = 0;
          dashLength = dasharray[dashIdx];
        }
        DirectionVector newDirectionVector;
        (newDirectionVector, dashLength) = directionVector.reduce(dashLength);
        // print(
        //   "idx: $dashIdx, length: $dashLength, directionVector: $newDirectionVector, offset: ${Offsets(directionVector.firstVector, newDirectionVector.firstVector).distance()}",
        //        );

        if (dashIdx % 2 == 0) {
          // draw line
          Offsets offsets = Offsets(directionVector.firstVector, newDirectionVector.firstVector);
          if (offsets.hasDistance()) dashed.add(offsets);
        }
        directionVector = newDirectionVector;
      }
      startOffset = pointinfo.offset;
    }
    // String debug = "";
    // for (int i = 0; i < dashed.length; i++) {
    //   debug += "*";
    //   debug += dashed[i].distance().toStringAsFixed(1);
    //   debug += "*";
    //   debug += " - ";
    //   if (i < dashed.length - 1) {
    //     double distance = sqrt(
    //       (dashed[i].end.dx - dashed[i + 1].start.dx) * (dashed[i].end.dx - dashed[i + 1].start.dx) +
    //           (dashed[i].end.dy - dashed[i + 1].start.dy) * (dashed[i].end.dy - dashed[i + 1].start.dy),
    //     );
    //     debug += distance.toStringAsFixed(1);
    //     debug += " - ";
    //   }
    // }
    // print(dasharray);
    // print(pointinfos);
    // print(debug);
    return dashed;
  }
}

////////////////////////////////////////////////////////////////////////////////

/// A helper class representing a directional vector between two points.
///
/// This is used for calculations involving dashed lines.
class DirectionVector {
  /// the relative width/height of the vector
  final Offset vector;

  /// the length of the vector
  final double length;

  /// The startpoint of the vector
  final Offset firstVector;

  /// The endpoint of the vector
  final Offset secondVector;

  const DirectionVector._({required this.vector, required this.length, required this.firstVector, required this.secondVector});

  factory DirectionVector.get(Offset firstVector, Offset secondVector) {
    Offset directionVector = Offset(secondVector.dx - firstVector.dx, secondVector.dy - firstVector.dy);

    double directionVectorLength = sqrt(directionVector.dx * directionVector.dx + directionVector.dy * directionVector.dy);

    return DirectionVector._(vector: directionVector, length: directionVectorLength, firstVector: firstVector, secondVector: secondVector);
  }

  factory DirectionVector.nil(Offset offset) {
    return DirectionVector._(vector: const Offset(0, 0), length: 0, firstVector: offset, secondVector: offset);
  }

  /// Returns a new vector starting after [smallVectorLength] and ending at [secondVector]
  /// Returns the remaining length of [smallVectorLength] if we cannot fully consume it
  (DirectionVector, double) reduce(double smallVectorLength) {
    if (smallVectorLength == 0) return (this, 0);
    if (smallVectorLength >= length) return (DirectionVector.nil(secondVector), smallVectorLength - length);
    var rescaleFactor = smallVectorLength / length;

    var rescaledVector = Offset(vector.dx * rescaleFactor, vector.dy * rescaleFactor);

    var newOffset = Offset(firstVector.dx + rescaledVector.dx, firstVector.dy + rescaledVector.dy);

    return (
      DirectionVector._(
        vector: Offset(secondVector.dx - newOffset.dx, secondVector.dy - newOffset.dy),
        length: length - smallVectorLength,
        firstVector: newOffset,
        secondVector: secondVector,
      ),
      0,
    );
  }

  @override
  String toString() {
    return 'DirectionVector{vector: $vector, length: $length, firstVector: $firstVector, secondVector: $secondVector}';
  }
}

////////////////////////////////////////////////////////////////////////////////

/// A simple data class to hold a start and end offset.
///
/// This is used for caching dashed line segments.
class Offsets {
  final Offset start;

  final Offset end;

  const Offsets(this.start, this.end);

  double distance() {
    return sqrt((end.dx - start.dx) * (end.dx - start.dx) + (end.dy - start.dy) * (end.dy - start.dy));
  }

  bool hasDistance() {
    return (end.dx - start.dx) != 0 || (end.dy - start.dy) != 0;
  }

  @override
  String toString() {
    return 'Offsets{start: $start, end: $end}';
  }
}
