import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';
import 'renderinstruction.dart';

/// Represents an icon along a polyline on the map.
class LineSymbol extends RenderInstruction with BitmapMixin {
  static final double REPEAT_GAP_DEFAULT = 200;
  static final double REPEAT_START_DEFAULT = 30;

  bool alignCenter = true;
  Display display = Display.IFSPACE;
  double dy = 0;
  final Map<int, double> dyScaled;
  int priority = 0;
  final String? relativePathPrefix;
  bool repeat = true;
  double? repeatGap;
  double? repeatStart;
  bool? rotate;
  Scale scale = Scale.STROKE;
  Position position = Position.CENTER;

  LineSymbol(this.relativePathPrefix)
      : dyScaled = new Map(),
        super() {
    this.rotate = true;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement,
      List<RenderInstruction> initPendings) {
    this.repeatGap = REPEAT_GAP_DEFAULT * displayModel.getScaleFactor();
    this.repeatStart = REPEAT_START_DEFAULT * displayModel.getScaleFactor();
    this.bitmapPercent = (100 * displayModel.getFontScaleFactor()).round();

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.ALIGN_CENTER == name) {
        this.alignCenter = "true" == (value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.POSITION == name) {
        this.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.REPEAT == name) {
        this.repeat = "true" == (value);
      } else if (RenderInstruction.REPEAT_GAP == name) {
        this.repeatGap = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.REPEAT_START == name) {
        this.repeatStart = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        this.rotate = "true" == (value);
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.bitmapHeight =
            XmlUtils.parseNonNegativeInteger(name, value).toDouble();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.bitmapPercent = (XmlUtils.parseNonNegativeInteger(name, value) *
                displayModel.getFontScaleFactor())
            .round();
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.bitmapWidth =
            XmlUtils.parseNonNegativeInteger(name, value).toDouble();
      } else {
        throw Exception("LineSymbol probs: unknown '$name'");
      }
    });
    if (bitmapSrc != null) initPendings.add(this);
  }

  @override
  void renderNode(RenderCallback renderCallback,
      final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback,
      final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    double? dyScale = this.dyScaled[renderContext.job.tile.zoomLevel];
    dyScale ??= this.dy;

    if (bitmap != null) {
      renderCallback.renderWaySymbol(
          renderContext,
          this.display,
          this.priority,
          this.bitmap!,
          dyScale,
          this.alignCenter,
          this.repeat,
          this.repeatGap,
          this.repeatStart,
          this.rotate,
          way,
          bitmapPaint);
    }
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scale == Scale.NONE) {
      scaleFactor = 1;
    }
    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<LineSymbol> initResources(SymbolCache? symbolCache) async {
    await initBitmap(symbolCache);
    return this;
  }
}
