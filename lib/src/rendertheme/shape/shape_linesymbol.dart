import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/scale.dart';

import '../../renderer/paintmixin.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import '../xml/symbol_finder.dart';
import 'shape_symbol.dart';

/// A PolylineContainer encapsulates the way data retrieved from a map file.
/// <p/>
/// The class uses deferred evaluation for computing the absolute and relative
/// pixel coordinates of the way as many ways will not actually be rendered on a
/// map. In order to save memory, after evaluation, the internally stored way is
/// released.
class ShapeLinesymbol extends ShapeSymbol {
  double dy = 0;

  bool repeat = true;

  late double repeatGap;

  late double repeatStart;

  bool rotate = true;

  Scale scale = Scale.STROKE;

  bool alignCenter = false;

  int lineSymbolMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT;

  ShapeLinesymbol.base(int level) : super.base(level);

  ShapeLinesymbol.scale(ShapeLinesymbol base, int zoomLevel)
      : super.scale(base, zoomLevel, SymbolFinder(null)) {
    //paintSrcMixinScale(base, zoomLevel);
    //bitmapSrcMixinScale(base, zoomLevel);
    dy = base.dy;
    repeat = base.repeat;
    repeatGap = base.repeatGap;
    repeatStart = base.repeatStart;
    rotate = base.rotate;
    scale = base.scale;
    position = base.position;
    alignCenter = base.alignCenter;
    lineSymbolMinZoomLevel = base.lineSymbolMinZoomLevel;

    if (this.scale == Scale.NONE) return;

    if (zoomLevel >= lineSymbolMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - lineSymbolMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      repeatGap = repeatGap * scaleFactor;
      repeatStart = repeatStart * scaleFactor;
      dy = dy * scaleFactor;
    }
  }

  void setRepeatGap(double repeatGap) {
    this.repeatGap = repeatGap;
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  void setLineSymbolMinZoomLevel(int lineSymbolMinZoomLevel) {
    this.lineSymbolMinZoomLevel = lineSymbolMinZoomLevel;
  }

  void setScaleFromValue(String value) {
    if (value.contains("ALL")) {
      scale = Scale.ALL;
    } else if (value.contains("NONE")) {
      scale = Scale.NONE;
    }
    scale = Scale.STROKE;
  }

  @override
  String getShapeType() {
    return "Linesymbol";
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (bitmapSrc == null) return;
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    //renderContext.labels.add(WayRenderInfo(wayProperties, shape));
    renderContext.addToClashDrawingLayer(
        level, WayRenderInfo(wayProperties, this));
  }
}
