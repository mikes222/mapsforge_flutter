import 'dart:math';

import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../graphics/position.dart';
import '../../renderer/paintmixin.dart';
import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../textkey.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import '../xml/symbol_finder.dart';
import 'paintsrcmixin.dart';
import 'textsrcmixin.dart';

class ShapeCaption extends Shape with PaintSrcMixin, TextSrcMixin {
  late double gap = 0;

  /// The position of this caption relative to the corresponding symbol. If the symbol is not set
  /// the position is always center
  Position position = Position.CENTER;

  String? symbolId;

  SymbolHolder? symbolHolder;

  TextKey? textKey;

  double dy = 0;

  ShapeCaption.base(int level) : super.base(level: level);

  ShapeCaption.scale(ShapeCaption base, int zoomLevel, SymbolFinder symbolFinder) : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    textSrcMixinScale(base, zoomLevel);
    gap = base.gap;
    position = base.position;
    priority = base.priority;
    symbolId = base.symbolId;
    textKey = base.textKey;
    dy = base.dy;
// do NOT copy symbolHolder. It is dependent on the zoomLevel

    if (zoomLevel >= strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
      double scaleFactor = pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      gap = gap * scaleFactor;
      dy = dy * scaleFactor;
    }
    if (symbolId != null) {
      symbolHolder = symbolFinder.findSymbolHolder(symbolId!);
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

  MapRectangle calculateBoundaryWithSymbol(double fontWidth, double fontHeight) {
    MapRectangle? symbolBoundary = symbolHolder?.shapeSymbol?.calculateBoundary();
//    print("shapeCaption in calculateOffsets pos $position, symbolHolder: $symbolHolder, captionBoundary: $fontWidth, $fontHeight, boundary: $symbolBoundary");
    if (position == Position.CENTER && symbolBoundary != null) {
      // sensible defaults: below if symbolContainer is present, center if not
      position = Position.BELOW;
    }

    if (symbolBoundary == null) {
      // symbol not available, draw the text at the center
      position = Position.CENTER;
      symbolBoundary = const MapRectangle(0, 0, 0, 0);
    }

    double halfWidth = fontWidth / 2;
    double halfHeight = fontHeight / 2;

    switch (position) {
      case Position.AUTO:
      case Position.CENTER:
        this.boundary = MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case Position.BELOW:
        this.boundary = MapRectangle(-halfWidth, symbolBoundary.bottom + 0 + this.gap + dy, halfWidth, symbolBoundary.bottom + fontHeight + this.gap + dy);
        break;
      case Position.BELOW_LEFT:
        this.boundary = MapRectangle(symbolBoundary.left - fontWidth - this.gap, symbolBoundary.bottom + 0 + this.gap + dy, symbolBoundary.left - 0 - this.gap,
            symbolBoundary.bottom + fontHeight + this.gap + dy);
        break;
      case Position.BELOW_RIGHT:
        this.boundary = MapRectangle(symbolBoundary.right + 0 + this.gap, symbolBoundary.bottom + 0 + this.gap + dy,
            symbolBoundary.right + fontWidth + this.gap, symbolBoundary.bottom + fontHeight + this.gap + dy);
        break;
      case Position.ABOVE:
        this.boundary = MapRectangle(-halfWidth, symbolBoundary.top - fontHeight - this.gap + dy, halfWidth, symbolBoundary.top - 0 - this.gap + dy);
        break;
      case Position.ABOVE_LEFT:
        this.boundary = MapRectangle(symbolBoundary.left - fontWidth - this.gap, symbolBoundary.top - fontHeight - this.gap + dy,
            symbolBoundary.left - 0 - this.gap, symbolBoundary.top + 0 - this.gap + dy);
        break;
      case Position.ABOVE_RIGHT:
        this.boundary = MapRectangle(symbolBoundary.right + 0 + this.gap, symbolBoundary.top - fontHeight - this.gap + dy,
            symbolBoundary.right + fontWidth + this.gap, symbolBoundary.top + 0 - this.gap + dy);
        break;
      case Position.LEFT:
        this.boundary = MapRectangle(symbolBoundary.left - fontWidth - this.gap, -halfHeight, symbolBoundary.left - 0 - this.gap, halfHeight);
        break;
      case Position.RIGHT:
        this.boundary = MapRectangle(symbolBoundary.right + 0 + this.gap, -halfHeight, symbolBoundary.right + fontHeight + this.gap, halfHeight);
        break;
    }
    return boundary!;
  }

  @override
  String getShapeType() {
    return "Caption";
  }

  @override
  String toString() {
    return 'ShapeCaption{level: $level, gap: $gap, position: $position, symbolId: $symbolId, symbolHolder: $symbolHolder, textKey: $textKey, dy: $dy}';
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {
    String? caption = textKey!.getValue(nodeProperties.tags);
    if (caption == null) {
      return;
    }

    //print("Rendering caption $caption for $nodeProperties");
    renderContext.labels.add(NodeRenderInfo(nodeProperties, this)..caption = caption);
  }

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null) {
      return;
    }

    //print("caption $caption");
    renderContext.labels.add(WayRenderInfo(wayProperties, this)..caption = caption);
  }
}
