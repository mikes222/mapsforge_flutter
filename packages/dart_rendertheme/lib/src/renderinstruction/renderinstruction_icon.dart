import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/map_display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Rendering instruction for Flutter font-based icons on the map.
///
/// This class handles the rendering of vector icons from Flutter's icon fonts
/// such as Material Icons. Unlike bitmap symbols, these icons are scalable
/// vector graphics that maintain quality at all zoom levels.
///
/// Key features:
/// - Vector-based icons from Flutter icon fonts
/// - Reusable icons with unique identifiers
/// - Rotation support with optional map alignment
/// - Positioning control relative to anchor points
/// - Support for both node (POI) and way (area) icons
class RenderinstructionIcon extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin implements RenderinstructionNode, RenderinstructionWay {
  /// Unique identifier for this icon, allowing reuse across the theme.
  String? id;

  /// Positioning of the icon relative to its anchor point.
  MapPositioning position = MapPositioning.CENTER;

  /// Rotation angle of the icon in radians.
  double theta = 0;

  /// Unicode code point of the icon in the font family.
  ///
  /// For example, the Material Icons 'ten_k' icon has code point 0xe000,
  /// corresponding to IconData(0xe000, fontFamily: 'MaterialIcons').
  int codePoint = 0;

  /// Font family name containing the icon glyphs.
  String fontFamily = "MaterialIcons";

  /// Creates a new icon rendering instruction for the specified drawing level.
  ///
  /// Initializes bitmap settings with full size rendering and appropriate
  /// minimum zoom level for text-related icons.
  ///
  /// [level] The drawing level (layer) for this icon instruction
  RenderinstructionIcon(int level) {
    this.level = level;
    setBitmapPercent(100);
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
  }

  /// Creates a zoom level specific copy of this icon instruction.
  ///
  /// Applies zoom level dependent scaling to bitmap properties while
  /// preserving icon identity, positioning, rotation, and font settings.
  ///
  /// [zoomlevel] Target zoom level for scaling calculations
  /// Returns a new scaled icon instruction
  @override
  RenderinstructionIcon forZoomlevel(int zoomlevel, int level) {
    RenderinstructionIcon renderinstruction = RenderinstructionIcon(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    renderinstruction.position = position;
    renderinstruction.theta = theta;
    renderinstruction.rotateWithMap = rotateWithMap;
    renderinstruction.codePoint = codePoint;
    renderinstruction.fontFamily = fontFamily;
    return renderinstruction;
  }

  @override
  String getType() {
    return "icon";
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;
      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.DISPLAY == name) {
        display = MapDisplay.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value));
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.ID == name) {
        id = value;
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.POSITION == name) {
        position = MapPositioning.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }
  }

  @override
  MapRectangle getBoundary() {
    if (boundary != null) return boundary!;

    double halfWidth = getBitmapWidth() / 2;
    double halfHeight = getBitmapHeight() / 2;

    switch (position) {
      case MapPositioning.AUTO:
      case MapPositioning.CENTER:
        boundary = MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case MapPositioning.BELOW:
        boundary = MapRectangle(-halfWidth, 0 + dy, halfWidth, getBitmapHeight() + dy);
        break;
      case MapPositioning.BELOW_LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), 0 + dy, 0, getBitmapHeight() + dy);
        break;
      case MapPositioning.BELOW_RIGHT:
        boundary = MapRectangle(0, 0 + dy, getBitmapWidth().toDouble(), getBitmapHeight() + dy);
        break;
      case MapPositioning.ABOVE:
        boundary = MapRectangle(-halfWidth, -getBitmapHeight() + dy, halfWidth, 0 + dy);
        break;
      case MapPositioning.ABOVE_LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), -getBitmapHeight() + dy, 0, 0 + dy);
        break;
      case MapPositioning.ABOVE_RIGHT:
        boundary = MapRectangle(0, -getBitmapHeight() + dy, getBitmapWidth().toDouble(), 0 + dy);
        break;
      case MapPositioning.LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), -halfHeight + dy, 0, halfHeight + dy);
        break;
      case MapPositioning.RIGHT:
        boundary = MapRectangle(0, -halfHeight + dy, getBitmapWidth().toDouble(), halfHeight + dy);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    if (bitmapSrc == null) return;
    layerContainer.addLabel(RenderInfoNode(nodeProperties, this));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null) return;

    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.addLabel(RenderInfoWay(wayProperties, this));
  }
}
