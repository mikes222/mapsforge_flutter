import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/**
 * Represents a polyline on the map.
 */
class Line extends RenderInstruction with BitmapMixin {
  //static final Pattern SPLIT_PATTERN = Pattern.compile(",");

  late double dy;
  late Map<int, double> dyScaled;
  final int level;
  final String? relativePathPrefix;
  Scale scale = Scale.STROKE;
  late MapPaint stroke;
  List<double>? strokeDasharray;
  late Map<int, MapPaint> strokes;
  late double strokeWidth;

  Line(GraphicFactory graphicFactory, DisplayModel displayModel, String elementName, this.level, this.relativePathPrefix)
      : super(
          graphicFactory,
          displayModel,
        ) {
    this.symbolCache = graphicFactory.symbolCache;
    strokeWidth = 1;
    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);
    this.stroke.setStrokeCap(Cap.ROUND);
    this.stroke.setStrokeJoin(Join.ROUND);
    this.stroke.setStrokeWidth(strokeWidth);
    strokes = new Map();
    dyScaled = new Map();
    dy = 0;
  }

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.src = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        this.strokeDasharray = parseFloatArray(name, value);
        for (int f = 0; f < this.strokeDasharray!.length; ++f) {
          this.strokeDasharray![f] = this.strokeDasharray![f] * displayModel.getScaleFactor();
        }
        this.stroke.setStrokeDasharray(this.strokeDasharray);
      } else if (RenderInstruction.STROKE_LINECAP == name) {
        this.stroke.setStrokeCap(Cap.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_LINEJOIN == name) {
        this.stroke.setStrokeJoin(Join.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.strokeWidth = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.height = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.percent = XmlUtils.parseNonNegativeInteger(name, value);
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.width = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else {
        throw new Exception("element hinich");
      }
    });
    if (src != null) initPendings.add(this);
  }

  MapPaint _getStrokePaint(int zoomLevel) {
    MapPaint? paint = strokes[zoomLevel];
    if (paint == null) {
      paint = this.stroke;
    }
    return paint;
  }

  static List<double> parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = dashEntries.map((e) => XmlUtils.parseNonNegativeFloat(name, e)).toList();
    // List<double>(dashEntries.length);
    // for (int i = 0; i < dashEntries.length; ++i) {
    //   dashIntervals[i] = XmlUtils.parseNonNegativeFloat(name, dashEntries[i]);
    // }
    return dashIntervals;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    MapPaint strokePaint = _getStrokePaint(renderContext.job.tile.zoomLevel);

    double? dyScale = this.dyScaled[renderContext.job.tile.zoomLevel];
    if (dyScale == null) {
      dyScale = this.dy;
    }
    renderCallback.renderWay(renderContext, strokePaint, dyScale, this.level, way);
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scale == Scale.NONE) {
      scaleFactor = 1;
    }
    MapPaint paint = graphicFactory.createPaintFrom(stroke);
    paint.setStrokeWidth(this.strokeWidth * scaleFactor);

    if (this.scale == Scale.ALL || this.scale == Scale.STROKE) {
      if (strokeDasharray != null) {
        List<double> strokeDasharrayScaled = this.strokeDasharray!.map((dash) {
          return dash * scaleFactor;
        }).toList();
        paint.setStrokeDasharray(strokeDasharrayScaled);
      }
    }

    //paint.setStrokeDasharray(this.strokeDasharray);
    strokes[zoomLevel] = paint;
    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<Line> initResources(GraphicFactory graphicFactory) async {
    await initBitmap(graphicFactory);
    if (bitmap != null) {
      // make sure the color is not transparent
      if (stroke.isTransparent()) stroke.setColorFromNumber(0xff000000);
      stroke.setBitmapShader(bitmap!);
      strokes.forEach((key, value) {
        // make sure the color is not transparent
        if (value.isTransparent()) value.setColorFromNumber(0xff000000);
        value.setBitmapShader(bitmap!);
      });
      //strokePaint.setBitmapShaderShift(way.getUpperLeft().getOrigin());
      //bitmap.incrementRefCount();
    }
    return this;
  }

  @override
  void dispose() {
    stroke.dispose();
    strokes.values.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }
}
