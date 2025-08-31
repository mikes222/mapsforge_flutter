import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_display.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/scale.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Rendering instruction for filled polygon areas on the map.
///
/// This class handles the rendering of closed polygons (areas) such as buildings,
/// parks, water bodies, and other filled regions. It supports both solid fill colors
/// and bitmap pattern fills, along with optional stroke outlines.
///
/// Key features:
/// - Solid color fills and bitmap pattern fills
/// - Optional stroke outlines with customizable properties
/// - Zoom level dependent scaling and visibility
/// - Support for display modes and rendering priorities
class RenderinstructionArea extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin, FillSrcMixin, StrokeSrcMixin implements RenderinstructionWay {
  /// Creates a new area rendering instruction for the specified drawing level.
  ///
  /// [level] The drawing level (layer) for this area instruction
  RenderinstructionArea(int level) : super() {
    this.level = level;
    // Disable bitmap scaling for areas to maintain visual quality
    setBitmapMinZoomLevel(65535);
    setBitmapPercent(100);
  }

  /// Creates a zoom level specific copy of this area instruction.
  ///
  /// Applies zoom level dependent scaling to all rendering properties
  /// including fill, stroke, and bitmap parameters.
  ///
  /// [zoomlevel] Target zoom level for scaling calculations
  /// Returns a new scaled area instruction
  @override
  RenderinstructionArea forZoomlevel(int zoomlevel, int level) {
    return RenderinstructionArea(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);
  }

  /// Returns the type identifier for this rendering instruction.
  @override
  String getType() {
    return "area";
  }

  /// Parses XML attributes to configure this area rendering instruction.
  ///
  /// Processes XML attributes such as fill color, stroke properties, bitmap sources,
  /// display modes, and other styling parameters from the theme definition.
  ///
  /// [rootElement] XML element containing the area instruction attributes
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
        if (scale == Scale.NONE) setStrokeMinZoomLevel(665535);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value));
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
    // boundary depends on the way
    throw UnimplementedError();
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.add(level, RenderInfoWay(wayProperties, this));
  }
}
