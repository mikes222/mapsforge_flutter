import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterrect.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../fillrule.dart';
import 'flutterpaint.dart';

class FlutterPath implements MapPath {
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
  void lineToMappoint(Mappoint point) {
    path.lineTo(point.x, point.y);
    points.add(Pointinfo(false, point.x, point.y));
    dashedPaths.clear();
  }

  @override
  void moveToMappoint(Mappoint point) {
    path.moveTo(point.x, point.y);
    points.add(Pointinfo(true, point.x, point.y));
    dashedPaths.clear();
  }

  @override
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
    int idx = 0;
    int dashIdx = 0;
    double dashLength = dasharray[dashIdx];
    double dashSpace = dasharray[dashIdx + 1];
    dashIdx += 2;
    DirectionVector directionVector = DirectionVector.nil(const Offset(0, 0));
    points.forEach((Pointinfo offset) {
      if (offset.start) {
        idx = 0;
        dashIdx = 0;
        dashLength = dasharray[dashIdx];
        dashSpace = dasharray[dashIdx + 1];
        dashIdx += 2;
      }
      if (idx == 0) {
        directionVector = DirectionVector.nil(offset.offset);
      } else {
        directionVector =
            DirectionVector.get(directionVector.secondVector, offset.offset);
        while (directionVector.length >= dashLength) {
          DirectionVector newDirectionVector =
              directionVector.reduce(dashLength);
          // print(
          //     "from: ${directionVector.firstVector} to ${newDirectionVector.firstVector} $dashLength");

          /// Draw a small line.
          uiCanvas.drawLine(directionVector.firstVector,
              newDirectionVector.firstVector, (paint as FlutterPaint).paint);
          dashed!.add(Offsets(
              directionVector.firstVector, newDirectionVector.firstVector));
          directionVector = newDirectionVector;
          // skip the gap
          directionVector = directionVector.reduce(dashSpace);
          if (dasharray.length < dashIdx + 2) {
            dashIdx = 0;
          }
          dashLength = dasharray[dashIdx];
          dashSpace = dasharray[dashIdx + 1];
          dashIdx += 2;
        }
        if (directionVector.length > 0) {
          /// Draw a small line.
          uiCanvas.drawLine(directionVector.firstVector,
              directionVector.secondVector, (paint as FlutterPaint).paint);
          dashed!.add(Offsets(
              directionVector.firstVector, directionVector.secondVector));
          dashLength -= directionVector.length;
          directionVector = DirectionVector.nil(directionVector.secondVector);
        }
      }
      ++idx;
    });
  }

  @override
  void drawLine(MapPaint paint, ui.Canvas uiCanvas) {
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

class DirectionVector {
  final Offset vector;
  final double length;

  final Offset firstVector;
  final Offset secondVector;

  DirectionVector({
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

    return DirectionVector(
      vector: directionVector,
      length: directionVectorLength,
      firstVector: firstVector,
      secondVector: secondVector,
    );
  }

  factory DirectionVector.nil(Offset offset) {
    return DirectionVector(
        vector: const Offset(0, 0),
        length: 0,
        firstVector: offset,
        secondVector: offset);
  }

  DirectionVector reduce(double smallVectorLength) {
    if (smallVectorLength >= length) return DirectionVector.nil(secondVector);
    var rescaleFactor = smallVectorLength / length;

    var rescaledVector =
        Offset(vector.dx * rescaleFactor, vector.dy * rescaleFactor);

    var newOffset = Offset(
        firstVector.dx + rescaledVector.dx, firstVector.dy + rescaledVector.dy);

    return DirectionVector(
      vector: Offset(
          secondVector.dx - newOffset.dx, secondVector.dy - newOffset.dy),
      length: length - smallVectorLength,
      firstVector: newOffset,
      secondVector: secondVector,
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

class Pointinfo {
  final bool start;

  final Offset offset;

  Pointinfo(this.start, double x, double y) : offset = Offset(x, y);
}
