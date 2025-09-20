import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_rect.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

/// A wrapper around Flutter's `ui.Path` to simplify path creation and drawing
/// for map rendering.
///
/// This class provides methods for adding points, lines, and rectangles to a path.
/// It also includes custom logic for drawing dashed lines, which is not natively
/// supported by Flutter's `Canvas.drawPath` in all cases.
class UiPath {
  static final _log = Logger('FlutterPath');

  final ui.Path _path = ui.Path();

  final List<Pointinfo> _points = [];

  /// A cache for dashed paths.
  final Map<int, List<Offsets>> _dashedPaths = {};

  UiPath();

  /// Clears the path and resets all internal state.
  void clear() {
    _path.reset();
    _points.clear();
    _dashedPaths.clear();
  }

  /// Closes the current sub-path by connecting the last point to the first.
  void close() {
    _path.close();
  }

  /// Returns true if the path is empty.
  bool isEmpty() {
    return _points.isEmpty;
  }

  /// Adds a straight line segment from the current point to the given point.
  void lineTo(double x, double y) {
    _path.lineTo(x, y);
    _points.add(Pointinfo(false, x, y));
    _dashedPaths.clear();
  }

  /// Starts a new sub-path at the given point.
  void moveTo(double x, double y) {
    _path.moveTo(x, y);
    _points.add(Pointinfo(true, x, y));
    _dashedPaths.clear();
  }

  /// Sets the fill rule for this path.
  void setFillRule(MapFillRule fillRule) {
    switch (fillRule) {
      case MapFillRule.EVEN_ODD:
        _path.fillType = ui.PathFillType.evenOdd;
        break;
      case MapFillRule.NON_ZERO:
        _path.fillType = ui.PathFillType.nonZero;
        break;
    }
  }

  /// Adds a straight line segment from the current point to the given [MappointRelative].
  void lineToMappoint(MappointRelative point) {
    _path.lineTo(point.dx, point.dy);
    _points.add(Pointinfo(false, point.dx, point.dy));
    _dashedPaths.clear();
  }

  /// Starts a new sub-path at the given [MappointRelative].
  void moveToMappoint(MappointRelative point) {
    _path.moveTo(point.dx, point.dy);
    _points.add(Pointinfo(true, point.dx, point.dy));
    _dashedPaths.clear();
  }

  /// Draws a dashed line along the path.
  ///
  /// This method manually calculates and draws the dashes and gaps, as Flutter's
  /// native dash support can be inconsistent.
  void drawDash(UiPaint paint, Canvas uiCanvas) {
    List<double> dasharray = paint.getStrokeDasharray()!;
    List<Offsets>? dashed = _dashedPaths[dasharray.hashCode];
    if (dashed != null) {
      for (var offsets in dashed) {
        uiCanvas.drawLine(offsets.start, offsets.end, paint.expose());
      }
      return;
    }
    dashed = [];
    _dashedPaths[dasharray.hashCode] = dashed;
    int dashIdx = 0;
    double dashLength = dasharray[dashIdx];
    Offset? startOffset;
    for (var offset in _points) {
      if (offset.start) {
        dashIdx = 0;
        dashLength = dasharray[dashIdx];
        startOffset = offset.offset;
        continue;
      }
      if (startOffset == null) {
        _log.warning("Startoffset is null for dash $dashed and points $_points");
        startOffset = offset.offset;
        continue;
      }
      DirectionVector directionVector = DirectionVector.get(startOffset, offset.offset);
      while (directionVector.length > 0) {
        if (dashIdx % 2 == 0) {
          // draw line
          double remainingLength = 0;

          /// Draw a small line.
          (directionVector, remainingLength) = _drawLine(paint, uiCanvas, directionVector, dashLength, dashed);
          if (remainingLength != 0) {
            // we should draw the remaining length at the next vector
            dashLength = remainingLength;
          } else {
            ++dashIdx;
            dashLength = dasharray[dashIdx];
          }
        } else {
          // skip space
          double remainingLength = 0;
          (directionVector, remainingLength) = directionVector.reduce(dashLength);
          if (remainingLength != 0) {
            // we should "draw" the remaining space at the next vector
            dashLength = remainingLength;
          } else {
            ++dashIdx;
            if (dashIdx == dasharray.length) dashIdx = 0;
            dashLength = dasharray[dashIdx];
          }
        }
      }
      startOffset = offset.offset;
    }
  }

  (DirectionVector, double) _drawLine(UiPaint paint, Canvas uiCanvas, DirectionVector directionVector, double dashLength, List<Offsets> dashed) {
    if (dashLength == 0) {
      return (directionVector, 0);
    }
    DirectionVector newDirectionVector;
    double remainingLength;
    (newDirectionVector, remainingLength) = directionVector.reduce(dashLength);
    // print(
    //     "from: ${directionVector.firstVector} to ${newDirectionVector.firstVector} $dashLength");

    uiCanvas.drawLine(directionVector.firstVector, newDirectionVector.firstVector, paint.expose());
    dashed.add(Offsets(directionVector.firstVector, newDirectionVector.firstVector));
    return (newDirectionVector, remainingLength);
  }

  /// Draws the path on the given canvas with the specified paint.
  ///
  /// This method handles both solid and dashed lines.
  void drawPath(UiPaint paint, ui.Canvas uiCanvas) {
    List<double>? dasharray = paint.getStrokeDasharray();
    if (dasharray != null && dasharray.length >= 2) {
      drawDash(paint, uiCanvas);
      return;
    }
    if (!_path.getBounds().overlaps(uiCanvas.getLocalClipBounds())) return;
    //    if (paint.isFillPaint()) {
    uiCanvas.drawPath(_path, paint.expose());
    return;
    //  }

    // https://github.com/flutter/flutter/issues/78543#issuecomment-885090581
    _points.forEachIndexed((int idx, Pointinfo point) {
      if (idx > 0 && !point.start) {
        // do NOT draw a line TO a new start point
        uiCanvas.drawLine(_points[idx - 1].offset, point.offset, paint.expose());
      }
    });
  }

  /// Adds a closed rectangle to the path.
  void addRect(UiRect rect) {
    _path.addRect(rect.expose());
    _points.add(Pointinfo(true, rect.getLeft(), rect.getTop()));
    _points.add(Pointinfo(false, rect.getRight(), rect.getTop()));
    _points.add(Pointinfo(false, rect.getRight(), rect.getBottom()));
    _points.add(Pointinfo(false, rect.getLeft(), rect.getBottom()));
    _points.add(Pointinfo(false, rect.getLeft(), rect.getTop()));
  }

  @override
  String toString() {
    return 'UiPath{_points: $_points}';
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
}

////////////////////////////////////////////////////////////////////////////////

/// A simple data class to hold a start and end offset.
///
/// This is used for caching dashed line segments.
class Offsets {
  final Offset start;

  final Offset end;

  const Offsets(this.start, this.end);
}

////////////////////////////////////////////////////////////////////////////////

/// A helper class that holds information about a point in a `UiPath`.
///
/// It stores the [offset] of the point and a boolean [start] flag to indicate
/// if this point begins a new sub-path.
class Pointinfo {
  /// true if a new path should start, can be multiple times in the array. Normally the
  /// first Pointinfo has the start=true
  final bool start;

  final Offset offset;

  Pointinfo(this.start, double x, double y) : offset = Offset(x, y);

  @override
  String toString() {
    return 'Pointinfo{start: $start, offset: $offset}';
  }
}
