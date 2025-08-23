import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/layer_container.dart';
import 'package:dart_rendertheme/src/model/nodeproperties.dart';
import 'package:dart_rendertheme/src/model/position.dart';
import 'package:dart_rendertheme/src/model/render_info_node.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/repeat_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/// Represents an icon along a polyline on the map.
class RenderinstructionLinesymbol extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin, RepeatSrcMixin implements RenderinstructionWay {
  static final double REPEAT_GAP_DEFAULT = 150;
  static final double REPEAT_START_DEFAULT = 30;

  Position position = Position.CENTER;

  bool alignCenter = true;

  int zoomlevel = -1;

  RenderinstructionLinesymbol(int level) {
    this.level = level;
  }

  @override
  RenderinstructionLinesymbol forZoomlevel(int zoomlevel) {
    RenderinstructionLinesymbol renderinstruction = RenderinstructionLinesymbol(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..repeatSrcMixinScale(this, zoomlevel);
    renderinstruction.position = position;
    renderinstruction.alignCenter = alignCenter;
    // we need the zoomlevel for calculating the position of the individual symbols
    renderinstruction.zoomlevel = zoomlevel;
    return renderinstruction;
  }

  @override
  String getType() {
    return "linesymbol";
  }

  void parse(XmlElement rootElement) {
    //initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setRepeatGap(REPEAT_GAP_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor());
    repeatStart = REPEAT_START_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.ALIGN_CENTER == name) {
        alignCenter = "true" == (value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getUserScaleFactor());
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
        if (scale == Scale.NONE) {
          setBitmapMinZoomLevel(65535);
        }
      } else if (Renderinstruction.POSITION == name) {
        position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.REPEAT == name) {
        repeat = "true" == (value);
      } else if (Renderinstruction.REPEAT_GAP == name) {
        setRepeatGap(double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (Renderinstruction.REPEAT_START == name) {
        repeatStart = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.ROTATE == name) {
        rotate = "true" == (value);
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * MapsforgeSettingsMgr().getFontScaleFactor().round());
      } else if (Renderinstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }
  }

  @override
  MapRectangle getBoundary() {
    double halfWidth = getBitmapWidth() / 2;
    double halfHeight = getBitmapHeight() / 2;
    MapRectangle boundary = MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
    return boundary;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null) return;
    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    //layerContainer.addClash(RenderInfoWay(wayProperties, this));
    _definePoints(layerContainer, wayProperties);
  }

  void _definePoints(LayerContainer layerContainer, WayProperties wayProperties) {
    PixelProjection projection = PixelProjection(zoomlevel);
    int skipPixels = repeatStart.round();

    List<List<Mappoint>> coordinatesAbsolute = wayProperties.getCoordinatesAbsolute();

    List<Mappoint?> outerList = coordinatesAbsolute[0];
    if (outerList.length < 2) return;

    // get the first way point coordinates
    Mappoint previous = outerList[0]!;

    // draw the symbolContainer on each way segment
    int segmentLengthRemaining;
    double segmentSkipPercentage;

    for (int i = 1; i < outerList.length; ++i) {
      // get the current way point coordinates
      Mappoint current = outerList[i]!;

      // calculate the length of the current segment (Euclidian distance)
      RelativeMappoint diff = current.offset(previous);
      double segmentLengthInPixel = sqrt(diff.dx * diff.dx + diff.dy * diff.dy);
      segmentLengthRemaining = segmentLengthInPixel.round();

      while (segmentLengthRemaining - skipPixels > repeatStart) {
        // calculate the percentage of the current segment to skip
        segmentSkipPercentage = skipPixels / segmentLengthRemaining;

        // move the previous point forward towards the current point
        previous = Mappoint(previous.x + diff.dx * segmentSkipPercentage, previous.y + diff.dy * segmentSkipPercentage);

        double radians = 0;
        if (rotate) {
          // if we do not rotate theta will be 0, which is correct
          radians = previous.radiansTo(current);
        }

        layerContainer.addClash(
          RenderInfoNode(
            NodeProperties(
              PointOfInterest(
                wayProperties.layer,
                wayProperties.getTags(),
                LatLong(projection.pixelYToLatitude(previous.y), projection.pixelXToLongitude(previous.x)),
              ),
              projection,
            ),
            this,
          )..rotateRadians = radians,
        );

        // check if the symbolContainer should only be rendered once
        if (!repeat) {
          return;
        }

        // recalculate the distances
        diff = current.offset(previous);

        // recalculate the remaining length of the current segment
        segmentLengthRemaining -= skipPixels;

        // set the amount of pixels to skip before repeating the symbolContainer
        skipPixels = repeatGap.round();
      }

      skipPixels -= segmentLengthRemaining;
      if (skipPixels < repeatStart) {
        skipPixels = repeatStart.round();
      }

      // set the previous way point coordinates for the next loop
      previous = current;
    }
  }
}
