import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/waydecorator.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';
import 'renderinstruction.dart';
import 'textkey.dart';

/**
 * Represents a text along a polyline on the map.
 */
class PathText extends RenderInstruction with TextMixin, PaintMixin {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  Display display = Display.IFSPACE;
  int priority = 0;
  Scale scale = Scale.STROKE;
  bool? repeat;
  double? repeatGap;
  double? repeatStart;
  bool? rotate;
  TextKey? textKey;

  PathText() {
    initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this.rotate = true;
    this.repeat = true;
  }

  @override
  void dispose() {
    disposePaintMixin();
    disposeTextMixin();
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    this.repeatGap = REPEAT_GAP_DEFAULT * displayModel.getScaleFactor();
    this.repeatStart = REPEAT_START_DEFAULT * displayModel.getScaleFactor();

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        this.textKey = TextKey.getInstance(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.FILL == name) {
        this.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        setFontFamily(value);
      } else if (RenderInstruction.FONT_SIZE == name) {
        this.setFontSize(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value)));
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
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.fontScaleFactor);
      } else {
        throw Exception("PathText probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, this.textKey);
  }

  @override
  void renderNode(final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    String? caption = this.textKey!.getValue(way.getTags());
    if (caption == null) {
      return;
    }

    WayDecorator.renderText(
        way.getUpperLeft(),
        caption,
        display,
        priority,
        getDy(renderContext.job.tile.zoomLevel),
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        getTextPaint(renderContext.job.tile.zoomLevel),
        repeat,
        repeatGap!,
        repeatStart!,
        rotate,
        way.getCoordinatesAbsolute(renderContext.projection),
        renderContext.labels);
  }

  @override
  void prepareScale(int zoomLevel) {
    if (this.scale == Scale.NONE) {
      return;
    }

    prepareScalePaintMixin(zoomLevel);
    prepareScaleTextMixin(zoomLevel);
  }
}
