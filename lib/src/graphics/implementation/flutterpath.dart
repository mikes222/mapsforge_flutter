import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterrect.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/model/relative_mappoint.dart';

import '../fillrule.dart';
import 'flutterpaint.dart';

class FlutterPath implements MapPath {
  static final _log = new Logger('FlutterPath');

  final ui.Path path = ui.Path();

  final List<Pointinfo> points = [];

  Map<int, List<Offsets>> dashedPaths = {};

  FlutterPath();

  @override
  void clear() {
    path.reset();
    points.clear();
    dashedPaths.clear();
  }

  @override
  void close() {
    path.close();
  }

  @override
  bool isEmpty() {
    return points.isEmpty;
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
    points.add(Pointinfo(false, x, y));
    dashedPaths.clear();
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
    points.add(Pointinfo(true, x, y));
    dashedPaths.clear();
  }

  @override
  void setFillRule(FillRule fillRule) {
    switch (fillRule) {
      case FillRule.EVEN_ODD:
        path.fillType = ui.PathFillType.evenOdd;
        break;
      case FillRule.NON_ZERO:
        path.fillType = ui.PathFillType.nonZero;
        break;
    }
  }

  @override
  void lineToMappoint(RelativeMappoint point) {
    path.lineTo(point.x, point.y);
    points.add(Pointinfo(false, point.x, point.y));
    dashedPaths.clear();
  }

  @override
  void moveToMappoint(RelativeMappoint point) {
    path.moveTo(point.x, point.y);
    points.add(Pointinfo(true, point.x, point.y));
    dashedPaths.clear();
  }

  void drawDash(MapPaint paint, Canvas uiCanvas) {
    List<double> dasharray = paint.getStrokeDasharray()!;
    List<Offsets>? dashed = dashedPaths[dasharray.hashCode];
    if (dashed != null) {
      dashed.forEach((Offsets offsets) {
        uiCanvas.drawLine(
            offsets.start, offsets.end, (paint as FlutterPaint).paint);
      });
      return;
    }
    dashed = [];
    dashedPaths[dasharray.hashCode] = dashed;
    int dashIdx = 0;
    double dashLength = dasharray[dashIdx];
    Offset? startOffset;
    points.forEach((Pointinfo offset) {
      if (offset.start) {
        dashIdx = 0;
        dashLength = dasharray[dashIdx];
        startOffset = offset.offset;
        return;
      }
      if (startOffset == null) {
        _log.warning("Startoffset is null for dash $dashed and points $points");
        startOffset = offset.offset;
        return;
      }
      DirectionVector directionVector =
          DirectionVector.get(startOffset!, offset.offset);
      while (directionVector.length > 0) {
        if (dashIdx % 2 == 0) {
          // draw line
          double remainingLength = 0;

          /// Draw a small line.
          (directionVector, remainingLength) =
              _drawLine(paint, uiCanvas, directionVector, dashLength, dashed!);
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
          (directionVector, remainingLength) =
              directionVector.reduce(dashLength);
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
    });
  }

  (DirectionVector, double) _drawLine(
      MapPaint paint,
      Canvas uiCanvas,
      DirectionVector directionVector,
      double dashLength,
      List<Offsets> dashed) {
    if (dashLength == 0) {
      return (directionVector, 0);
    }
    DirectionVector newDirectionVector;
    double remainingLength;
    (newDirectionVector, remainingLength) = directionVector.reduce(dashLength);
    // print(
    //     "from: ${directionVector.firstVector} to ${newDirectionVector.firstVector} $dashLength");

    uiCanvas.drawLine(directionVector.firstVector,
        newDirectionVector.firstVector, (paint as FlutterPaint).paint);
    dashed.add(
        Offsets(directionVector.firstVector, newDirectionVector.firstVector));
    return (newDirectionVector, remainingLength);
  }

  @override
  void drawPath(MapPaint paint, ui.Canvas uiCanvas) {
    List<double>? dasharray = paint.getStrokeDasharray();
    if (dasharray != null && dasharray.length >= 2) {
      drawDash(paint, uiCanvas);
      return;
    } else {
      if (paint.getStyle() == Style.FILL) {
        uiCanvas.drawPath(path, (paint as FlutterPaint).paint);
        return;
      }
    }

    // https://github.com/flutter/flutter/issues/78543#issuecomment-885090581
    points.forEachIndexed((int idx, Pointinfo point) {
      if (idx > 0 && !point.start) {
        // do NOT draw a line TO a new start point
        uiCanvas.drawLine(points[idx - 1].offset, point.offset,
            (paint as FlutterPaint).paint);
      }
    });
  }

  @override
  void addRect(MapRect mapRect) {
    path.addRect((mapRect as FlutterRect).rect);
    points.add(Pointinfo(true, mapRect.getLeft(), mapRect.getTop()));
    points.add(Pointinfo(false, mapRect.getRight(), mapRect.getTop()));
    points.add(Pointinfo(false, mapRect.getRight(), mapRect.getBottom()));
    points.add(Pointinfo(false, mapRect.getLeft(), mapRect.getBottom()));
    points.add(Pointinfo(false, mapRect.getLeft(), mapRect.getTop()));
  }
}

////////////////////////////////////////////////////////////////////////////////

/// A line from [firstVector] to [secondVector].
class DirectionVector {
  /// the relative width/height of the vector
  final Offset vector;

  /// the length of the vector
  final double length;

  /// The startpoint of the vector
  final Offset firstVector;

  /// The endpoint of the vector
  final Offset secondVector;

  const DirectionVector._({
    required this.vector,
    required this.length,
    required this.firstVector,
    required this.secondVector,
  });

  factory DirectionVector.get(Offset firstVector, Offset secondVector) {
    Offset directionVector = Offset(
        secondVector.dx - firstVector.dx, secondVector.dy - firstVector.dy);

    double directionVectorLength =
        sqrt(pow(directionVector.dx, 2) + pow(directionVector.dy, 2));

    return DirectionVector._(
      vector: directionVector,
      length: directionVectorLength,
      firstVector: firstVector,
      secondVector: secondVector,
    );
  }

  factory DirectionVector.nil(Offset offset) {
    return DirectionVector._(
        vector: const Offset(0, 0),
        length: 0,
        firstVector: offset,
        secondVector: offset);
  }

  /// Returns a new vector starting after [smallVectorLength] and ending at [secondVector]
  /// Returns the remaining length of [smallVectorLength] if we cannot fully consume it
  (DirectionVector, double) reduce(double smallVectorLength) {
    if (smallVectorLength == 0) return (this, 0);
    if (smallVectorLength >= length)
      return (DirectionVector.nil(secondVector), smallVectorLength - length);
    var rescaleFactor = smallVectorLength / length;

    var rescaledVector =
        Offset(vector.dx * rescaleFactor, vector.dy * rescaleFactor);

    var newOffset = Offset(
        firstVector.dx + rescaledVector.dx, firstVector.dy + rescaledVector.dy);

    return (
      DirectionVector._(
        vector: Offset(
            secondVector.dx - newOffset.dx, secondVector.dy - newOffset.dy),
        length: length - smallVectorLength,
        firstVector: newOffset,
        secondVector: secondVector,
      ),
      0
    );
  }
}

////////////////////////////////////////////////////////////////////////////////

class Offsets {
  final Offset start;

  final Offset end;

  const Offsets(this.start, this.end);
}

////////////////////////////////////////////////////////////////////////////////

/// Infos about the point for a path. Whenever a new path should start
/// the [start] property is true
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
