import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/repeat_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/textkey.dart';
import 'package:dart_rendertheme/src/util/waydecorator.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/**
 * Represents a text along a polyline on the map.
 */
class RenderinstructionPathtext extends Renderinstruction
    with BaseSrcMixin, TextSrcMixin, StrokeColorSrcMixin, FillColorSrcMixin, RepeatSrcMixin
    implements RenderinstructionWay {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  TextKey? textKey;

  int zoomlevel = -1;

  RenderinstructionPathtext(int level) {
    this.level = level;
    //initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    //initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
  }

  @override
  RenderinstructionPathtext forZoomlevel(int zoomlevel) {
    RenderinstructionPathtext renderinstruction = RenderinstructionPathtext(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..strokeColorSrcMixinScale(this, zoomlevel)
      ..fillColorSrcMixinScale(this, zoomlevel)
      ..repeatSrcMixinScale(this, zoomlevel);
    renderinstruction.textKey = textKey;
    // we need the zoomlevel for calculating the position of the individual texts
    renderinstruction.zoomlevel = zoomlevel;
    return renderinstruction;
  }

  @override
  String getType() {
    return "pathtext";
  }

  void parse(XmlElement rootElement) {
    maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    repeatGap = REPEAT_GAP_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    repeatStart = REPEAT_START_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.K == name) {
        textKey = TextKey(value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getUserScaleFactor());
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.FONT_FAMILY == name) {
        setFontFamily(MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.FONT_SIZE == name) {
        setFontSize(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (Renderinstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.REPEAT == name) {
        repeat = value == "true";
      } else if (Renderinstruction.REPEAT_GAP == name) {
        repeatGap = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.REPEAT_START == name) {
        repeatStart = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.ROTATE == name) {
        rotate = value == "true";
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.K, textKey);
  }

  @override
  MapRectangle getBoundary() {
    // boundary depends on the text, so fake it
    double widthEstimated = maxTextWidth;
    double heightEstimated = fontSize;
    return MapRectangle(-widthEstimated / 2, -heightEstimated / 2, widthEstimated / 2, heightEstimated / 2);
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null || caption.trim().isEmpty) {
      return;
    }
    LineSegmentPath? stringPath = _calculateStringPath(wayProperties, dy);
    if (stringPath == null || stringPath.segments.isEmpty) {
      return;
    }

    double widthEstimated = maxTextWidth;
    LineSegmentPath fullPath = WayDecorator.reducePathForText(stringPath, widthEstimated);
    if (fullPath.segments.isEmpty) return;

    PixelProjection projection = PixelProjection(zoomlevel);
    for (var segment in fullPath.segments) {
      // So text isn't upside down
      bool doInvert = segment.end.x < segment.start.x;
      Mappoint start;
      double diff = (segment.length() - widthEstimated) / 2;
      if (doInvert) {
        //start = segment.end.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff + widthEstimated);
      } else {
        //start = segment.start.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff);
      }

      layerContainer.addClash(
        RenderInfoNode(
            NodeProperties(
              PointOfInterest(
                wayProperties.layer,
                wayProperties.getTags(),
                LatLong(projection.pixelYToLatitude(start.y), projection.pixelXToLongitude(start.x)),
              ),
              projection,
            ),
            this,
          )
          ..rotateRadians = segment.getTheta()
          ..caption = caption,
      );
    }

    // layerContainer.addClash(
    //   RenderInfoWay(wayProperties, this)
    //     ..caption = caption
    //     ..stringPath = stringPath,
    // );
  }

  LineSegmentPath? _calculateStringPath(WayProperties wayProperties, double dy) {
    List<List<Mappoint>> coordinatesAbsolute = wayProperties.getCoordinatesAbsolute();

    if (coordinatesAbsolute.isEmpty || coordinatesAbsolute[0].length < 2) {
      return null;
    }
    List<Mappoint> c;
    if (dy == 0) {
      c = coordinatesAbsolute[0];
    } else {
      c = WayProperties.parallelPath(coordinatesAbsolute[0], dy);
    }

    if (c.length < 2) {
      return null;
    }

    LineSegmentPath fullPath = LineSegmentPath();
    for (int i = 1; i < c.length; i++) {
      LineSegment segment = LineSegment(c[i - 1], c[i]);
      fullPath.segments.add(segment);
    }
    return fullPath;
  }
}
