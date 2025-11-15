import 'dart:ui' as ui;
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_rect.dart';
import 'package:mapsforge_flutter_renderer/src/util/path_helper.dart';
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
  final Map<String, List<Offsets>> _dashedPaths = {};

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
    List<Offsets>? dashed = _dashedPaths[dasharray.join()];
    dashed ??= PathHelper.calculateDashes(_points, dasharray);
    _dashedPaths[dasharray.join()] = dashed;
    for (var offsets in dashed) {
      uiCanvas.drawLine(offsets.start, offsets.end, paint.expose());
    }
  }

  /// Draws the path on the given canvas with the specified paint.
  ///
  /// This method handles both solid and dashed lines.
  void drawPath(UiPaint paint, ui.Canvas uiCanvas) {
    List<double>? dasharray = paint.getStrokeDasharray();
    if (dasharray != null) {
      drawDash(paint, uiCanvas);
      return;
    }
    if (!_path.getBounds().overlaps(uiCanvas.getLocalClipBounds())) return;
    //    if (paint.isFillPaint()) {
    uiCanvas.drawPath(_path, paint.expose());
    return;
    //  }

    // https://github.com/flutter/flutter/issues/78543#issuecomment-885090581
    // _points.forEachIndexed((int idx, Pointinfo point) {
    //   if (idx > 0 && !point.start) {
    //     // do NOT draw a line TO a new start point
    //     uiCanvas.drawLine(_points[idx - 1].offset, point.offset, paint.expose());
    //   }
    // });
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
