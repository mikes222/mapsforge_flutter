import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/// Rendering instruction for circular shapes on the map.
///
/// This class handles the rendering of circular elements such as POI markers,
/// circular area highlights, or decorative elements. Circles can have both
/// fill colors and stroke outlines with configurable radius and positioning.
///
/// Key features:
/// - Configurable radius with optional zoom-level scaling
/// - Fill colors and stroke outlines
/// - Positioning relative to anchor points
/// - Zoom-dependent size scaling for better visibility
class RenderinstructionCircle extends Renderinstruction with BaseSrcMixin, FillSrcMixin, StrokeSrcMixin implements RenderinstructionNode {
  /// The radius of the circle in pixels.
  double radius = 10;

  /// Whether the radius should scale with zoom level changes.
  bool scaleRadius = true;

  /// Positioning of the circle relative to its anchor point.
  MapPositioning position = MapPositioning.CENTER;

  /// Creates a new circle rendering instruction for the specified drawing level.
  ///
  /// [level] The drawing level (layer) for this circle instruction
  RenderinstructionCircle(int level) {
    this.level = level;
  }

  /// Creates a zoom level specific copy of this circle instruction.
  ///
  /// Applies zoom level dependent scaling to fill, stroke, and optionally
  /// radius properties based on the scaleRadius setting.
  ///
  /// [zoomlevel] Target zoom level for scaling calculations
  /// Returns a new scaled circle instruction
  @override
  RenderinstructionCircle forZoomlevel(int zoomlevel, int level) {
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

  /// Returns the type identifier for this rendering instruction.
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
        display = MapDisplay.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
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
        position = MapPositioning.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.RADIUS, radius);
  }

  @override
  MapRectangle getBoundary(RenderInfo renderInfo) {
    if (boundary != null) return boundary!;
    double halfWidth = radius;
    if (!isStrokeTransparent()) halfWidth += strokeWidth / 2;
    switch (position) {
      case MapPositioning.AUTO:
      case MapPositioning.CENTER:
        boundary = MapRectangle(-halfWidth, -halfWidth + dy, halfWidth, halfWidth + dy);
        break;
      case MapPositioning.BELOW:
        boundary = MapRectangle(-halfWidth, 0 + dy, halfWidth, halfWidth * 2 + dy);
        break;
      case MapPositioning.BELOW_LEFT:
        boundary = MapRectangle(-halfWidth * 2, 0 + dy, 0, halfWidth * 2 + dy);
        break;
      case MapPositioning.BELOW_RIGHT:
        boundary = MapRectangle(0, 0 + dy, halfWidth * 2, halfWidth * 2 + dy);
        break;
      case MapPositioning.ABOVE:
        boundary = MapRectangle(-halfWidth, -halfWidth * 2 + dy, halfWidth, 0 + dy);
        break;
      case MapPositioning.ABOVE_LEFT:
        boundary = MapRectangle(-halfWidth * 2, -halfWidth * 2 + dy, 0, 0 + dy);
        break;
      case MapPositioning.ABOVE_RIGHT:
        boundary = MapRectangle(0, -halfWidth * 2 + dy, halfWidth * 2, 0 + dy);
        break;
      case MapPositioning.LEFT:
        boundary = MapRectangle(-halfWidth * 2, -halfWidth + dy, 0, halfWidth + dy);
        break;
      case MapPositioning.RIGHT:
        boundary = MapRectangle(0, -halfWidth + dy, halfWidth * 2, halfWidth + dy);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    layerContainer.add(level, RenderInfoNode<RenderinstructionCircle>(nodeProperties, this));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}
}
