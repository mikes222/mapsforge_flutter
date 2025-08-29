import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/map_display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Rendering instruction for bitmap symbols and icons on the map.
///
/// This class handles the rendering of bitmap-based symbols such as POI icons,
/// directional arrows, and other graphical elements. Symbols can be defined
/// once with an ID and reused throughout the theme, supporting positioning,
/// rotation, and scaling.
///
/// Key features:
/// - Reusable symbols with unique identifiers
/// - Bitmap scaling and positioning control
/// - Rotation support with optional map alignment
/// - Support for both node (POI) and way (area) symbols
class RenderinstructionSymbol extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin implements RenderinstructionNode, RenderinstructionWay {
  /// Unique identifier for this symbol, allowing reuse across the theme.
  String? id;

  /// Positioning of the symbol relative to its anchor point.
  MapPositioning positioning = MapPositioning.CENTER;

  /// Rotation angle of the symbol in radians.
  double theta = 0;

  /// Creates a new symbol rendering instruction for the specified drawing level.
  ///
  /// Initializes bitmap settings with full size rendering and appropriate
  /// minimum zoom level for text-related symbols.
  ///
  /// [level] The drawing level (layer) for this symbol instruction
  RenderinstructionSymbol(int level) {
    this.level = level;
    setBitmapPercent(100);
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
  }

  /// Creates a zoom level specific copy of this symbol instruction.
  ///
  /// Applies zoom level dependent scaling to bitmap properties while
  /// preserving symbol identity, positioning, and rotation settings.
  ///
  /// [zoomlevel] Target zoom level for scaling calculations
  /// Returns a new scaled symbol instruction
  @override
  RenderinstructionSymbol forZoomlevel(int zoomlevel, int level) {
    RenderinstructionSymbol renderinstruction = RenderinstructionSymbol(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    renderinstruction.positioning = positioning;
    renderinstruction.theta = theta;
    renderinstruction.rotateWithMap = rotateWithMap;
    return renderinstruction;
  }

  void dispose() {
    shapePainter?.dispose();
  }

  /// Returns the type identifier for this rendering instruction.
  @override
  String getType() {
    return "symbol";
  }

  /// Parses XML attributes to configure this symbol rendering instruction.
  ///
  /// Processes XML attributes such as symbol ID, bitmap source, positioning,
  /// rotation, and other styling parameters from the theme definition.
  ///
  /// [rootElement] XML element containing the symbol instruction attributes
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
        positioning = MapPositioning.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
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

    switch (positioning) {
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
