import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';
import 'renderinstruction.dart';
import 'textkey.dart';

/**
 * Represents a text along a polyline on the map.
 */
class PathText extends RenderInstruction {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  Display display = Display.IFSPACE;
  double dy = 0;
  final Map<int, double> dyScaled;
  late MapPaint fill;
  final Map<int, MapPaint> fills;
  double fontSize = 10;
  int priority = 0;
  Scale scale = Scale.STROKE;
  late MapPaint stroke;
  final Map<int, MapPaint> strokes;
  bool? repeat;
  double? repeatGap;
  double? repeatStart;
  bool? rotate;
  TextKey? textKey;

  PathText(GraphicFactory graphicFactory, DisplayModel displayModel)
      : fills = new Map(),
        strokes = new Map(),
        dyScaled = new Map(),
        super(graphicFactory, displayModel) {
    this.fill = graphicFactory.createPaint();
    this.fill.setColor(Color.BLACK);
    this.fill.setStyle(Style.FILL);
    //this.fill.setTextAlign(Align.CENTER);
    this.rotate = true;
    this.repeat = true;

    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);
    //this.stroke.setTextAlign(Align.CENTER);
    this.stroke.setStrokeWidth(1);
  }

  @override
  void dispose() {}

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    this.repeatGap = REPEAT_GAP_DEFAULT * displayModel.getScaleFactor();
    this.repeatStart = REPEAT_START_DEFAULT * displayModel.getScaleFactor();

    MapFontFamily fontFamily = MapFontFamily.DEFAULT;
    MapFontStyle fontStyle = MapFontStyle.NORMAL;

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        this.textKey = TextKey.getInstance(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values.firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.FILL == name) {
        this.fill.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        fontFamily = MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.FONT_SIZE == name) {
        this.fontSize = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.FONT_STYLE == name) {
        fontStyle = MapFontStyle.values.firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.REPEAT == name) {
        this.repeat = value == "true";
      } else if (RenderInstruction.REPEAT_GAP == name) {
        this.repeatGap = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.REPEAT_START == name) {
        this.repeatStart = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        this.rotate = value == "true";
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.stroke.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor());
      } else {
        throw Exception("PathText probs");
      }
    });

    this.fill.setTypeface(fontFamily, fontStyle);
    this.stroke.setTypeface(fontFamily, fontStyle);

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), RenderInstruction.K, this.textKey);
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint? paint = fills[zoomLevel];
    paint ??= this.fill;
    return paint;
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = strokes[zoomLevel];
    paint ??= this.stroke;
    return paint;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    String? caption = this.textKey!.getValue(way.getTags());
    if (caption == null) {
      return;
    }

    double? dyScale = this.dyScaled[renderContext.job.tile.zoomLevel];
    dyScale ??= this.dy;

    renderCallback.renderWayText(
        renderContext,
        this.display,
        this.priority,
        caption,
        dyScale,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        this.repeat,
        this.repeatGap,
        this.repeatStart,
        this.rotate,
        way);
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
    MapPaint zlPaint = graphicFactory.createPaintFrom(this.fill);
    if (zoomLevel >= 22)
      zlPaint.setTextSize(this.fontSize * scaleFactor * (zoomLevel - 20));
    else
      zlPaint.setTextSize(this.fontSize * scaleFactor);
    this.fills[zoomLevel] = zlPaint;

    MapPaint zlStroke = graphicFactory.createPaintFrom(this.stroke);
    if (zoomLevel >= 22)
      zlStroke.setTextSize(this.fontSize * scaleFactor * (zoomLevel - 20));
    else
      zlStroke.setTextSize(this.fontSize * scaleFactor);
    this.strokes[zoomLevel] = zlStroke;
  }

  @override
  Future<RenderInstruction> initResources(GraphicFactory graphicFactory) {
    return Future.value(this);
  }
}
