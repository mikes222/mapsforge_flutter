import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/// Represents a polyline on the map.
class Line extends RenderInstruction with BitmapMixin, PaintMixin {
  //static final Pattern SPLIT_PATTERN = Pattern.compile(",");

  late double dy;
  final Map<int, double> dyScaled = {};
  final int level;
  final String? relativePathPrefix;
  Scale scale = Scale.STROKE;

  Line(String elementName, this.level, this.relativePathPrefix) : super() {
    initPaintMixin();

    dy = 0;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement,
      List<RenderInstruction> initPendings) {
    this.bitmapPercent = (100 * displayModel.getFontScaleFactor()).round();

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = parseFloatArray(name, value);
        if (displayModel.getScaleFactor() != 1)
          for (int f = 0; f < dashArray.length; ++f) {
            dashArray[f] = dashArray[f] * displayModel.getScaleFactor();
          }
        this.setStrokeDashArray(dashArray);
      } else if (RenderInstruction.STROKE_LINECAP == name) {
        this.setStrokeCap(Cap.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_LINEJOIN == name) {
        this.setStrokeJoin(Join.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
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
        throw new Exception("element hinich");
      }
    });

    if (bitmapSrc != null) initPendings.add(this);
  }

  static List<double> parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = dashEntries
        .map((e) => XmlUtils.parseNonNegativeFloat(name, e))
        .toList();
    // List<double>(dashEntries.length);
    // for (int i = 0; i < dashEntries.length; ++i) {
    //   dashIntervals[i] = XmlUtils.parseNonNegativeFloat(name, dashEntries[i]);
    // }
    return dashIntervals;
  }

  @override
  void renderNode(RenderCallback renderCallback,
      final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback,
      final RenderContext renderContext, PolylineContainer way) {
    MapPaint strokePaint = getStrokePaint(renderContext.job.tile.zoomLevel);

    double? dyScale = this.dyScaled[renderContext.job.tile.zoomLevel];
    dyScale ??= this.dy;

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    renderCallback.renderWay(
        renderContext, strokePaint, dyScale, this.level, way);
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scale == Scale.NONE) {
      return;
    }
    scaleMixinStrokeWidth(scaleFactor, zoomLevel);

    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<Line> initResources(SymbolCache? symbolCache) async {
    await initBitmap(symbolCache);
    if (bitmap != null) {
      setStrokeBitmapShader(bitmap!);
    }
    return this;
  }

  @override
  void dispose() {
    mixinDispose();
    super.dispose();
  }
}
