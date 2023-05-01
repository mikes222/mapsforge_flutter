import 'dart:math';

import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../graphics/position.dart';
import '../../renderer/paintmixin.dart';
import '../renderinstruction/textkey.dart';
import '../xml/rulebuilder.dart';
import 'paintsrcmixin.dart';
import 'textsrcmixin.dart';

class ShapeCaption extends Shape with PaintSrcMixin, TextSrcMixin {
  double _horizontalOffset = 0;

  double _verticalOffset = 0;

  int level = 0;

  late double gap = 0;

  /// The position of this caption relative to the corresponding symbol. If the symbol is not set
  /// the position is always center
  Position position = Position.CENTER;

  String? symbolId;

  SymbolHolder? symbolHolder;

  TextKey? textKey;

  double dy = 0;

  ShapeCaption.base() : super.base();

  ShapeCaption.scale(ShapeCaption base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    textSrcMixinScale(base, zoomLevel);
    _horizontalOffset = base._horizontalOffset;
    _verticalOffset = base._verticalOffset;
    gap = base.gap;
    position = base.position;
    priority = base.priority;
    symbolId = base.symbolId;
    textKey = base.textKey;
    dy = base.dy;
    level = base.level;
// do NOT copy symbolHolder. It is dependent on the zoomLevel

    if (zoomLevel >= strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      gap = gap * scaleFactor;
      dy = dy * scaleFactor;
    }
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  @override
  MapRectangle calculateBoundary() {
    // the boundary is dependent on the text which is a property of renderInfo
    throw UnimplementedError();
    //if (boundary != null) return boundary!;
    // boundary = MapRectangle(
    //     -_boxWidth / 2 + _horizontalOffset,
    //     -_boxHeight / 2 + _verticalOffset,
    //     _boxWidth / 2 + _horizontalOffset,
    //     _boxHeight / 2 + _verticalOffset);

    //return boundary!;
  }

  void calculateOffsets(double fontWidth, double fontHeight,
      [MapRectangle? symbolBoundary]) {
    _verticalOffset = 0;
    _horizontalOffset = 0;
    // print(
    //     "shapeCaption in calculateOffsets pos $position, symbolHolder: $symbolHolder, captionBoundary: $_boxWidth, $_boxHeight");

    if (symbolBoundary == null) {
      if (position == Position.CENTER &&
          symbolHolder?.shapeSymbol?.bitmapSrc != null) {
        // sensible defaults: below if symbolContainer is present, center if not
        position = Position.BELOW;
      }
      symbolBoundary = symbolHolder?.shapeSymbol?.calculateBoundary();
      if (symbolBoundary == null) {
        position = Position.CENTER;
        return;
      }
    }

    switch (position) {
      case Position.CENTER:
        break;
      case Position.BELOW:
        _verticalOffset +=
            symbolBoundary.bottom + fontHeight / 2 + this.gap + dy;
        break;
      case Position.ABOVE:
        _verticalOffset += symbolBoundary.top - fontHeight / 2 - this.gap + dy;
        break;
      case Position.BELOW_LEFT:
        _horizontalOffset += symbolBoundary.left - fontWidth / 2 - this.gap;
        _verticalOffset +=
            symbolBoundary.bottom + fontHeight / 2 + this.gap + dy;
        break;
      case Position.ABOVE_LEFT:
        _horizontalOffset += symbolBoundary.left - fontWidth / 2 - this.gap;
        _verticalOffset += symbolBoundary.top - fontHeight / 2 - this.gap + dy;
        break;
      case Position.LEFT:
        _horizontalOffset += symbolBoundary.left - fontWidth / 2 - this.gap;
        _verticalOffset +=
            symbolBoundary.top + symbolBoundary.getHeight() / 2 + dy;
        break;
      case Position.BELOW_RIGHT:
        _horizontalOffset += symbolBoundary.right + fontWidth / 2 + this.gap;
        _verticalOffset +=
            symbolBoundary.bottom + fontHeight / 2 + this.gap + dy;
        break;
      case Position.ABOVE_RIGHT:
        _horizontalOffset += symbolBoundary.right + fontWidth / 2 + this.gap;
        _verticalOffset += symbolBoundary.top - fontHeight / 2 - this.gap + dy;
        break;
      case Position.RIGHT:
        _horizontalOffset += symbolBoundary.right + fontWidth / 2 + this.gap;
        _verticalOffset +=
            symbolBoundary.top + symbolBoundary.getHeight() / 2 + dy;
        break;
      default:
        throw new Exception("Position invalid");
    }
  }

  @override
  String getShapeType() {
    return "Caption";
  }

  double get horizontalOffset => _horizontalOffset;

  double get verticalOffset => _verticalOffset;

  @override
  String toString() {
    return 'ShapeCaption{_horizontalOffset: $_horizontalOffset, _verticalOffset: $_verticalOffset, level: $level, gap: $gap, position: $position, symbolId: $symbolId, textKey: $textKey, dy: $dy}';
  }
}
