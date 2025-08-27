import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_hillshading.dart';
import 'package:dart_rendertheme/src/xml/rulebuilder.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

/// Builder class for parsing XML theme files and creating RenderTheme instances.
/// 
/// This class handles the parsing of XML-based rendering theme files, converting
/// them into structured RenderTheme objects. It supports theme customization through
/// element exclusion and provides comprehensive error handling during parsing.
/// 
/// Key features:
/// - XML theme file parsing and validation
/// - Rule hierarchy construction
/// - Element exclusion for theme customization
/// - Version compatibility checking
/// - Comprehensive error reporting
class RenderThemeBuilder {
  static final _log = new Logger('RenderThemeBuilder');

  // XML attribute and element constants
  
  /// XML attribute for base stroke width scaling factor.
  static final String BASE_STROKE_WIDTH = "base-stroke-width";
  
  /// XML attribute for base text size scaling factor.
  static final String BASE_TEXT_SIZE = "base-text-size";
  
  /// XML attribute for map background color.
  static final String MAP_BACKGROUND = "map-background";
  
  /// XML attribute for background color outside map bounds.
  static final String MAP_BACKGROUND_OUTSIDE = "map-background-outside";
  
  /// Current supported render theme version.
  static final int RENDER_THEME_VERSION = 6;
  
  /// XML attribute for theme version.
  static final String VERSION = "version";
  
  /// XML namespace declaration.
  static final String XMLNS = "xmlns";
  
  /// XML Schema Instance namespace declaration.
  static final String XMLNS_XSI = "xmlns:xsi";
  
  /// XML Schema location attribute.
  static final String XSI_SCHEMALOCATION = "xsi:schemaLocation";

  /// Base stroke width scaling factor from theme definition.
  double baseStrokeWidth = 1;

  /// Base text size scaling factor from theme definition.
  double baseTextSize = 1;

  /// Whether the theme defines background color for areas outside the map.
  bool? hasBackgroundOutside;
  
  /// Map background color in ARGB format.
  int? mapBackground;
  
  /// Background color for areas outside map bounds in ARGB format.
  int? mapBackgroundOutside;
  
  /// Theme file version number.
  late int version;
  
  /// Stack of rule builders for hierarchical rule construction.
  final List<RuleBuilder> ruleBuilderStack = [];
  
  /// Current nesting level during XML parsing.
  int _level = 0;
  
  /// Maximum drawing level found in the theme.
  int maxLevel = 0;

  /// Hash string for theme identification and caching.
  String forHash = "";

  /// Set of element IDs to exclude from rendering for theme customization.
  final Set<String> excludeIds;

  /// Private constructor for creating builder instances.
  /// 
  /// [excludeIds] Optional set of element IDs to exclude from rendering
  RenderThemeBuilder._({this.excludeIds = const {}});

  /// Creates a RenderTheme from XML content string.
  /// 
  /// Parses the provided XML content and builds a complete RenderTheme object.
  /// Supports element exclusion for theme customization.
  /// 
  /// [content] XML theme content as string
  /// [excludeIds] Optional set of element IDs to exclude from rendering
  /// Returns the parsed RenderTheme
  /// Throws FormatException if XML parsing fails
  static Rendertheme createFromString(String content, {Set<String> excludeIds = const {}}) {
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder._(excludeIds: excludeIds);
    renderThemeBuilder._parseXml(content);
    renderThemeBuilder.forHash =
        "${MapsforgeSettingsMgr().getUserScaleFactor()}_${MapsforgeSettingsMgr().getFontScaleFactor()}_${MapsforgeSettingsMgr().tileSize}";
    return renderThemeBuilder._build();
  }

  /// Builds and returns a rendertheme by loading a rendertheme file. This
  /// is a convienience-function. If desired we can also implement some caching
  /// so that we do not need to parse the same file over and over again.
  static Future<Rendertheme> createFromFile(String filename, {Set<String> excludeIds = const {}}) async {
    File file = File(filename);
    List<int> bytes = await file.readAsBytes();
    String content = const Utf8Decoder().convert(bytes);
    return RenderThemeBuilder.createFromString(content, excludeIds: excludeIds);
  }

  /// @return a new {@code RenderTheme} instance.
  Rendertheme _build() {
    assert(ruleBuilderStack.isNotEmpty);
    List<Rule> rules = [];
    for (var ruleBuilder in ruleBuilderStack) {
      if (!ruleBuilder.impossible) {
        Rule rule = ruleBuilder.build();
        rules.add(rule);
        rule.parent = null;
      }
    }
    Rendertheme renderTheme = Rendertheme(levels: maxLevel, rulesList: rules);
    for (Rule rule in rules) {
      rule.secondPass();
    }
    return renderTheme;
  }

  ///
  /// Parses a given xml string and creates the renderinstruction-structure. The renderinstruction classes serves two purposes:
  /// On the one hand to parse the xml and create the tree structure and on the other hand to render ways and pois
  /// appropriately and draw the respective content.
  ///
  void _parseXml(String content) {
    assert(content.length > 10);
    int time = DateTime.now().millisecondsSinceEpoch;
    XmlDocument document = XmlDocument.parse(content);
    assert(document.children.length > 0);
    bool foundRendertheme = false;
    for (XmlNode node in document.children) {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          break;
        case XmlNodeType.PROCESSING:
          break;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node as XmlElement;
            if (element.name.toString() != "rendertheme") throw Exception("Invalid root node ${element.name.toString()}");
            foundRendertheme = true;
            _parseRendertheme(element);
            break;
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.COMMENT:
          break;
        case XmlNodeType.DOCUMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_FRAGMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_TYPE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DECLARATION:
          break;
        default:
          break;
      }
    }
    assert(foundRendertheme);
    for (RuleBuilder ruleBuilder in ruleBuilderStack) {
      ruleBuilder.validateTree();
    }
    //_log.info("Found ${initPendings.length} items for lazy initialization");
  }

  void _parseRendertheme(XmlElement rootElement) {
    for (var attribute in rootElement.attributes) {
      String name = attribute.name.toString();
      String value = attribute.value;
      //_log.info("checking $name=$value");
      if (XMLNS == name) {
        continue;
      } else if (XMLNS_XSI == name) {
        continue;
      } else if (XSI_SCHEMALOCATION == name) {
        continue;
      } else if (VERSION == name) {
        version = int.parse(value);
        if (version > RENDER_THEME_VERSION) {
          throw Exception("unsupported render theme version: $version");
        }
      } else if (MAP_BACKGROUND == name) {
        //        this.mapBackground = XmlUtils.getColor(
        //            graphicFactory, value, displayModel.getThemeCallback(), null);
      } else if (MAP_BACKGROUND_OUTSIDE == name) {
        //        this.mapBackgroundOutside = XmlUtils.getColor(
        //            graphicFactory, value, displayModel.getThemeCallback(), null);
        hasBackgroundOutside = true;
      } else if (BASE_STROKE_WIDTH == name) {
        baseStrokeWidth = XmlUtils.parseNonNegativeFloat(name, value);
      } else if (BASE_TEXT_SIZE == name) {
        baseTextSize = XmlUtils.parseNonNegativeFloat(name, value);
      } else {
        throw Exception("$name=$value");
      }
    }
    assert(rootElement.children.isNotEmpty);
    bool foundElement = false;
    for (XmlNode node in rootElement.children) {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          break;
        case XmlNodeType.PROCESSING:
          break;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node as XmlElement;
            foundElement = true;
            if (element.name.toString() == "rule") {
              // Pass the excludeIds from this builder into each new RuleBuilder.
              RuleBuilder ruleBuilder = RuleBuilder(_level, excludeIds: excludeIds);
              ruleBuilder.parse(element);
              ruleBuilderStack.add(ruleBuilder);
              ++_level;
              maxLevel = max(maxLevel, _level);
              maxLevel = max(maxLevel, ruleBuilder.maxLevel);
              break;
            } else if ("hillshading" == element.name.toString()) {
              RenderinstructionHillshading hillshading = RenderinstructionHillshading(_level);
              hillshading.parse(element);

              //      if (this.categories == null || category == null || this.categories.contains(category)) {
              //hillShadings.add(hillshading);
              //      }
              //print("Time ${DateTime.now().millisecondsSinceEpoch - time} after hillshading");
              break;
            } else if ("stylemenu" == element.name.toString()) {
              // TODO: handle stylemenu if needed.
              break;
            }
            throw Exception("Invalid node ${element.name.toString()}");
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.COMMENT:
          break;
        case XmlNodeType.DOCUMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_FRAGMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_TYPE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DECLARATION:
          break;
        default:
          break;
      }
    }
    assert(foundElement);
  }
}
