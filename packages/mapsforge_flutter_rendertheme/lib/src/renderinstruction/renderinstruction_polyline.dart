import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/scale.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Rendering instruction for polylines (open paths) on the map.
///
/// This class handles the rendering of linear features such as roads, paths,
/// rivers, boundaries, and other line-based map elements. It supports stroke
/// styling, bitmap patterns, and various line cap and join styles.
///
/// Key features:
/// - Stroke styling with customizable width, color, and patterns
/// - Bitmap pattern fills along the line path
/// - Line cap styles (round, square, butt)
/// - Line join styles (round, bevel, miter)
/// - Zoom level dependent scaling and visibility
class RenderinstructionPolyline extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin, StrokeSrcMixin implements RenderinstructionWay {
  /// Optional identifier for this polyline instruction.
  String? id;

  /// From Tiramisu theme. curve=cubic. Not implemented yet
  String? curve;

  /// Creates a new polyline rendering instruction for the specified drawing level.
  ///
  /// Initializes bitmap settings to maintain visual quality by disabling
  /// bitmap scaling which can cause visual artifacts on linear features.
  ///
  /// [level] The drawing level (layer) for this polyline instruction
  RenderinstructionPolyline(int level) {
    this.level = level;
    // Disable bitmap scaling for lines to prevent visual artifacts
    setBitmapPercent(100);
    setBitmapMinZoomLevel(65535);
  }

  /// Creates a zoom level specific copy of this polyline instruction.
  ///
  /// Applies zoom level dependent scaling to all rendering properties
  /// including stroke width, bitmap patterns, and other styling parameters.
  ///
  /// [zoomlevel] Target zoom level for scaling calculations
  /// Returns a new scaled polyline instruction
  @override
  RenderinstructionPolyline forZoomlevel(int zoomlevel, int level) {
    RenderinstructionPolyline renderinstruction = RenderinstructionPolyline(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    renderinstruction.curve = curve;
    return renderinstruction;
  }

  /// Returns the type identifier for this rendering instruction.
  @override
  String getType() {
    return "polyline";
  }

  /// Parses XML attributes to configure this polyline rendering instruction.
  ///
  /// Processes XML attributes such as stroke properties, bitmap sources,
  /// line caps, joins, and other styling parameters from the theme definition.
  ///
  /// [rootElement] XML element containing the polyline instruction attributes
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
        if (scale == Scale.NONE) {
          setBitmapMinZoomLevel(65535);
        }
      } else if (Renderinstruction.ID == name) {
        id = value;
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = _parseFloatArray(name, value);
        setStrokeDashArray(dashArray);
      } else if (Renderinstruction.STROKE_LINECAP == name) {
        setStrokeCap(MapCap.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.STROKE_LINEJOIN == name) {
        setStrokeJoin(MapJoin.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.CURVE == name) {
        curve = value;
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }
  }

  List<double> _parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = dashEntries.map((e) => XmlUtils.parseNonNegativeFloat(name, e)).toList();
    if (dashIntervals.isEmpty) {
      throw Exception("Attribute '$name' must have at least 2 comma-separated values: $dashString");
    }
    if (dashIntervals.length % 2 == 1) {
      dashIntervals.add(0);
    }
    if (MapsforgeSettingsMgr().getDeviceScaleFactor() != 1) {
      for (int f = 0; f < dashIntervals.length; ++f) {
        dashIntervals[f] = dashIntervals[f] * MapsforgeSettingsMgr().getDeviceScaleFactor();
      }
    }
    return dashIntervals;
  }

  @override
  MapRectangle getBoundary(RenderInfo renderInfo) {
    // boundary depends on the area
    throw UnimplementedError();
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null && isStrokeTransparent()) return;
    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.add(level, RenderInfoWay<RenderinstructionPolyline>(wayProperties, this));
  }

  @override
  String toString() {
    return 'RenderinstructionPolyline{id: $id, curve: $curve, strokeDashArray: $strokeDashArray, dy: $dy, scale: $scale, strokeCap: $strokeCap, strokeJoin: $strokeJoin, strokeWidth: $strokeWidth, strokeColor: ${strokeColor.toRadixString(16)}, bitmapSrc: $bitmapSrc, super: ${super.toString()}}';
  }
}
