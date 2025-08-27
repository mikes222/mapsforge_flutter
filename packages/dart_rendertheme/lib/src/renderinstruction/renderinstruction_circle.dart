import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/// Represents a round area on the map.
class RenderinstructionCircle extends Renderinstruction with BaseSrcMixin, FillSrcMixin, StrokeSrcMixin implements RenderinstructionNode {
  /// the radius of the circle in pixels
  double radius = 10;

  bool scaleRadius = true;

  Position position = Position.CENTER;

  RenderinstructionCircle(int level) {
    this.level = level;
  }

  @override
  RenderinstructionCircle forZoomlevel(int zoomlevel) {
    RenderinstructionCircle renderinstruction = RenderinstructionCircle(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);

    renderinstruction.scaleRadius = scaleRadius;
    renderinstruction.radius = radius;
    renderinstruction.position = position;
    if (scaleRadius) {
      if (zoomlevel >= strokeMinZoomLevel) {
        double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, strokeMinZoomLevel);
        renderinstruction.radius = radius * scaleFactor;
      }
    }
    return renderinstruction;
  }

  @override
  String getType() {
    return "circle";
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.RADIUS == name || Renderinstruction.R == name) {
        radius = XmlUtils.parseNonNegativeFloat(name, value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value));
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.SCALE_RADIUS == name) {
        scaleRadius = value == "true";
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.POSITION == name) {
        position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.RADIUS, radius);
  }

  @override
  MapRectangle getBoundary() {
    if (boundary != null) return boundary!;
    double halfWidth = radius;
    if (!isStrokeTransparent()) halfWidth += strokeWidth / 2;
    switch (position) {
      case Position.AUTO:
      case Position.CENTER:
        boundary = MapRectangle(-halfWidth, -halfWidth + dy, halfWidth, halfWidth + dy);
        break;
      case Position.BELOW:
        boundary = MapRectangle(-halfWidth, 0 + dy, halfWidth, halfWidth * 2 + dy);
        break;
      case Position.BELOW_LEFT:
        boundary = MapRectangle(-halfWidth * 2, 0 + dy, 0, halfWidth * 2 + dy);
        break;
      case Position.BELOW_RIGHT:
        boundary = MapRectangle(0, 0 + dy, halfWidth * 2, halfWidth * 2 + dy);
        break;
      case Position.ABOVE:
        boundary = MapRectangle(-halfWidth, -halfWidth * 2 + dy, halfWidth, 0 + dy);
        break;
      case Position.ABOVE_LEFT:
        boundary = MapRectangle(-halfWidth * 2, -halfWidth * 2 + dy, 0, 0 + dy);
        break;
      case Position.ABOVE_RIGHT:
        boundary = MapRectangle(0, -halfWidth * 2 + dy, halfWidth * 2, 0 + dy);
        break;
      case Position.LEFT:
        boundary = MapRectangle(-halfWidth * 2, -halfWidth + dy, 0, halfWidth + dy);
        break;
      case Position.RIGHT:
        boundary = MapRectangle(0, -halfWidth + dy, halfWidth * 2, halfWidth + dy);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    layerContainer.add(RenderInfoNode<RenderinstructionCircle>(nodeProperties, this));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}
}
