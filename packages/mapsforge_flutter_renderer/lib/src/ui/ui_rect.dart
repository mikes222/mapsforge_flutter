import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/model.dart';

/// A wrapper around Flutter's `ui.Rect` to provide additional utility methods.
///
/// This class simplifies working with rectangles by providing methods for
/// accessing properties like center, width, and height, and for creating
/// offset copies.
class UiRect {
  final ui.Rect _rect;

  Mappoint? _center;

  /// Creates a new `UiRect` from the given coordinates.
  UiRect(double left, double top, double right, double bottom)
    : assert(bottom >= top),
      assert(right >= left),
      _rect = ui.Rect.fromLTRB(left, top, right, bottom);

  /// Returns the left coordinate of the rectangle.
  double getLeft() => _rect.left;

  /// Returns the top coordinate of the rectangle.
  double getTop() => _rect.top;

  /// Returns the right coordinate of the rectangle.
  double getRight() => _rect.right;

  /// Returns the bottom coordinate of the rectangle.
  double getBottom() => _rect.bottom;

  /// Creates a new `UiRect` that is offset by the given x and y values.
  UiRect offset(double x, double y) {
    return UiRect(getLeft() + x, getTop() + y, getRight() + x, getBottom() + y);
  }

  /// Returns the center point of the rectangle.
  Mappoint getCenter() {
    if (_center != null) return _center!;
    _center = Mappoint((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2);
    return _center!;
  }

  /// Returns the height of the rectangle.
  double getHeight() {
    return _rect.bottom - _rect.top;
  }

  /// Returns the width of the rectangle.
  double getWidth() {
    return _rect.right - _rect.left;
  }

  /// Exposes the underlying `ui.Rect` object for direct use.
  ui.Rect expose() => _rect;
}
