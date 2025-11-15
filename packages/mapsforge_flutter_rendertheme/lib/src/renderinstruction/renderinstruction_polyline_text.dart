import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/repeat_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/textkey.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/// Represents a text along a polyline on the map.
class RenderinstructionPolylineText extends Renderinstruction
    with BaseSrcMixin, TextSrcMixin, StrokeSrcMixin, FillSrcMixin, RepeatSrcMixin
    implements RenderinstructionWay {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  TextKey? textKey;

  int zoomlevel = -1;

  RenderinstructionPolylineText(int level) {
    this.level = level;
    //initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    //initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setRepeatGap(REPEAT_GAP_DEFAULT);
    setRepeatStart(REPEAT_START_DEFAULT);
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
  }

  @override
  RenderinstructionPolylineText forZoomlevel(int zoomlevel, int level) {
    RenderinstructionPolylineText renderinstruction = RenderinstructionPolylineText(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..repeatSrcMixinScale(this, zoomlevel);
    renderinstruction.textKey = textKey;
    // we need the zoomlevel for calculating the position of the individual texts
    renderinstruction.zoomlevel = zoomlevel;
    return renderinstruction;
  }

  @override
  String getType() {
    return "polylinetext";
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.K == name) {
        textKey = TextKey(value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = MapDisplay.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value));
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.FONT_FAMILY == name) {
        setFontFamily(MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.FONT_SIZE == name) {
        setFontSize(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.REPEAT == name) {
        repeat = value == "true";
      } else if (Renderinstruction.REPEAT_GAP == name) {
        setRepeatGap(double.parse(value));
      } else if (Renderinstruction.REPEAT_START == name) {
        setRepeatStart(double.parse(value));
      } else if (Renderinstruction.ROTATE == name) {
        rotate = value == "true";
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.TEXT_ORIENTATION == name) {
        // left, not yet implemented
      } else if (Renderinstruction.CAT == name) {
        cat = value;
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.K, textKey);
  }

  @override
  MapRectangle getBoundary(RenderInfo renderInfo) {
    MapSize textSize = getEstimatedTextBoundary(renderInfo.caption ?? "", strokeWidth);
    if (renderInfo is RenderInfoNode) {
      if (!_isBoxMoreHorizontal(renderInfo.rotateRadians)) {
        textSize = MapSize(width: textSize.height, height: textSize.width);
      }
    }
    return MapRectangle(-textSize.width / 2, -textSize.height / 2, textSize.width / 2, textSize.height / 2);
  }

  bool _isBoxMoreHorizontal(double rotationRadians) {
    // Normalize rotation to [0, π/2] range
    double normalizedRotation = (rotationRadians.abs()) % (pi / 2);

    // If closer to 0, it's horizontal; if closer to π/2, it's vertical
    return normalizedRotation < pi / 4;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null || caption.trim().isEmpty) {
      return;
    }
    caption = caption.trim();
    LineSegmentPath? lineSegmentPath = wayProperties.calculateStringPath(dy);
    if (lineSegmentPath == null || lineSegmentPath.segments.isEmpty) {
      return;
    }

    MapSize textSize = getEstimatedTextBoundary(caption, strokeWidth);
    lineSegmentPath = lineSegmentPath.reducePathForText(textSize.width, repeatStart, repeatGap);
    if (lineSegmentPath.segments.isEmpty) return;

    PixelProjection projection = PixelProjection(zoomlevel);
    for (var segment in lineSegmentPath.segments) {
      // So text isn't upside down
      bool doInvert = segment.end.x < segment.start.x;
      Mappoint start;
      double diff = (segment.length() - textSize.width) / 2;
      if (doInvert) {
        //start = segment.end.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff + textSize.width);
      } else {
        //start = segment.start.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff);
      }

      layerContainer.addClash(
        RenderInfoNode(
          NodeProperties(
            PointOfInterest(
              wayProperties.layer,
              wayProperties.getTags().tags,
              LatLong(projection.pixelYToLatitude(start.y), projection.pixelXToLongitude(start.x)),
            ),
            projection,
          ),
          this,
          rotateRadians: segment.getTheta(),
          caption: caption,
        ),
      );
    }
  }
}
