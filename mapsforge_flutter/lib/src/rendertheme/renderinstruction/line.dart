import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/**
 * Represents a polyline on the map.
 */
class Line extends RenderInstruction {
  //static final Pattern SPLIT_PATTERN = Pattern.compile(",");

  bool bitmapCreated;
  double dy;
  Map<int, double> dyScaled;
  final int level;
  final String relativePathPrefix;
  Scale scale = Scale.STROKE;
  Bitmap shaderBitmap;
  String src;
  MapPaint stroke;
  List<double> strokeDasharray;
  Map<int, MapPaint> strokes;
  double strokeWidth;

  Line(GraphicFactory graphicFactory, DisplayModel displayModel, symbolCache, String elementName, this.level, this.relativePathPrefix)
      : super(graphicFactory, displayModel, symbolCache) {
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
    bitmapCreated = false;
  }

  @override
  void destroy() {
    // no.op
  }

  Future<void> parse(XmlElement rootElement) async {
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
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, null, this));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        this.strokeDasharray = parseFloatArray(name, value);
        for (int f = 0; f < this.strokeDasharray.length; ++f) {
          this.strokeDasharray[f] = this.strokeDasharray[f] * displayModel.getScaleFactor();
        }
        this.stroke.setDashPathEffect(this.strokeDasharray);
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

    try {
      shaderBitmap = await createBitmap(relativePathPrefix, src);
    } catch (ioException, stacktrace) {
      print(ioException.toString());
      //print(stacktrace);
    }
    bitmapCreated = true;
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint paint = strokes[zoomLevel];
    if (paint == null) {
      paint = this.stroke;
    }
    return paint;
  }

  static List<double> parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = List<double>(dashEntries.length);
    for (int i = 0; i < dashEntries.length; ++i) {
      dashIntervals[i] = XmlUtils.parseNonNegativeFloat(name, dashEntries[i]);
    }
    return dashIntervals;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    MapPaint strokePaint = getStrokePaint(renderContext.job.tile.zoomLevel);

    if (strokePaint != null && shaderBitmap != null) {
      strokePaint.setBitmapShader(shaderBitmap);
      strokePaint.setBitmapShaderShift(way.getUpperLeft().getOrigin());
      shaderBitmap.incrementRefCount();
    }

    double dyScale = this.dyScaled[renderContext.job.tile.zoomLevel];
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
    if (this.stroke != null) {
      MapPaint paint = graphicFactory.createPaintFrom(stroke);
      paint.setStrokeWidth(this.strokeWidth * scaleFactor);
      if (this.scale == Scale.ALL) {
        List<double> strokeDasharrayScaled = new List<double>(this.strokeDasharray.length);
        for (int i = 0; i < strokeDasharray.length; i++) {
          strokeDasharrayScaled[i] = this.strokeDasharray[i] * scaleFactor;
        }
        paint.setDashPathEffect(strokeDasharrayScaled);
      }
      strokes[zoomLevel] = paint;
    }

    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }
}
