import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_hillshading.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../rendertheme/rule/rendertheme.dart';
import 'rulebuilder.dart';

/**
 * A builder for {@link RenderTheme} instances.
 */
class RenderThemeBuilder {
  static final _log = new Logger('RenderThemeBuilder');

  static final String BASE_STROKE_WIDTH = "base-stroke-width";
  static final String BASE_TEXT_SIZE = "base-text-size";
  static final String MAP_BACKGROUND = "map-background";
  static final String MAP_BACKGROUND_OUTSIDE = "map-background-outside";
  static final int RENDER_THEME_VERSION = 6;
  static final String VERSION = "version";
  static final String XMLNS = "xmlns";
  static final String XMLNS_XSI = "xmlns:xsi";
  static final String XSI_SCHEMALOCATION = "xsi:schemaLocation";

  /// The rendertheme can set the base stroke with factor
  double baseStrokeWidth = 1;

  /// The rendertheme can set the base text size factor
  double baseTextSize = 1;

  bool? hasBackgroundOutside;
  int? mapBackground;
  int? mapBackgroundOutside;
  late int version;
  final List<RuleBuilder> ruleBuilderStack = [];
  int _level = 0;
  int maxLevel = 0;

  String forHash = "";

  RenderThemeBuilder();

  /// Builds and returns a rendertheme by loading a rendertheme-file. This
  /// is a convienience-function. If desired we can also implement some caching
  /// so that we do not need to parse the same file over and over again.
  static Future<RenderTheme> create(
      DisplayModel displayModel, String filename) async {
    ByteData bytes = await rootBundle.load(filename);
    String content = const Utf8Decoder().convert(bytes.buffer.asUint8List());
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    renderThemeBuilder.parseXml(displayModel, content);
    renderThemeBuilder.forHash =
        "${displayModel.deviceScaleFactor}_${displayModel.fontScaleFactor}_${displayModel.tileSize}";
    RenderTheme renderTheme = renderThemeBuilder.build();
    return renderTheme;
  }

  /**
   * @return a new {@code RenderTheme} instance.
   */
  RenderTheme build() {
    assert(ruleBuilderStack.length > 0);
    RenderTheme renderTheme = RenderTheme(this);
    ruleBuilderStack.forEach((ruleBuilder) {
      Rule rule = ruleBuilder.build();
      renderTheme.addRule(rule);
    });
    return renderTheme;
  }

  ///
  /// Parses a given xml string and creates the renderinstruction-structure. The renderinstruction classes serves two purposes:
  /// On the one hand to parse the xml and create the tree structure and on the other hand to render ways and pois
  /// appropriately and draw the respective content.
  ///
  void parseXml(DisplayModel displayModel, String content) {
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
            if (element.name.toString() != "rendertheme")
              throw Exception("Invalid root node ${element.name.toString()}");
            foundRendertheme = true;
            _parseRendertheme(displayModel, element);
            break;
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.COMMENT:
          // throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_FRAGMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DOCUMENT_TYPE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
        case XmlNodeType.DECLARATION:
          break;
      }
    }
    assert(foundRendertheme);
    for (RuleBuilder ruleBuilder in ruleBuilderStack) {
      ruleBuilder.validateTree();
    }
    //_log.info("Found ${initPendings.length} items for lazy initialization");
  }

  void _parseRendertheme(DisplayModel displayModel, XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      //_log.info("checking $name=$value");

      if (XMLNS == name) {
        return;
      } else if (XMLNS_XSI == name) {
        return;
      } else if (XSI_SCHEMALOCATION == name) {
        return;
      } else if (VERSION == name) {
        this.version = int.parse(value);
        if (this.version > RENDER_THEME_VERSION) {
          throw new Exception("unsupported render theme version: $version");
        }
      } else if (MAP_BACKGROUND == name) {
//        this.mapBackground = XmlUtils.getColor(
//            graphicFactory, value, displayModel.getThemeCallback(), null);
      } else if (MAP_BACKGROUND_OUTSIDE == name) {
//        this.mapBackgroundOutside = XmlUtils.getColor(
//            graphicFactory, value, displayModel.getThemeCallback(), null);
        this.hasBackgroundOutside = true;
      } else if (BASE_STROKE_WIDTH == name) {
        this.baseStrokeWidth = XmlUtils.parseNonNegativeFloat(name, value);
      } else if (BASE_TEXT_SIZE == name) {
        this.baseTextSize = XmlUtils.parseNonNegativeFloat(name, value);
      } else {
        throw Exception(name + "=" + value);
      }
    });
    assert(rootElement.children.length > 0);
    bool foundElement = false;
    bool foundRule = false;
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
              RuleBuilder ruleBuilder = RuleBuilder(null, _level);
              ruleBuilder.parse(displayModel, element);
              ruleBuilderStack.add(ruleBuilder);
              foundRule = true;
              ++_level;
              maxLevel = max(maxLevel, _level);
              maxLevel = max(maxLevel, ruleBuilder.maxLevel);
              //print("Time ${DateTime.now().millisecondsSinceEpoch - time} after rule ${element.toString()}");
              break;
            } else if ("hillshading" == element.name.toString()) {
              String? category = null;
              int minZoom = 5;
              int maxZoom = 17;
              int layer = 5;
              double magnitude = 64;
              bool always = false;

              rootElement.attributes.forEach((element) {
                String name = element.name.toString();
                String value = element.value;

                if ("cat" == name) {
                  category = value;
                } else if ("zoom-min" == name) {
                  minZoom = XmlUtils.parseNonNegativeByte("zoom-min", value);
                } else if ("zoom-max" == name) {
                  maxZoom = XmlUtils.parseNonNegativeByte("zoom-max", value);
                } else if ("magnitude" == name) {
                  magnitude =
                      XmlUtils.parseNonNegativeInteger("magnitude", value)
                          .toDouble();
                  if (magnitude > 255)
                    throw new Exception(
                        "Attribute 'magnitude' must not be > 255");
                } else if ("always" == name) {
                  always = "true" == (value);
                } else if ("layer" == name) {
                  layer = XmlUtils.parseNonNegativeByte("layer", value);
                }
              });

              RenderinstructionHillshading hillshading = RenderinstructionHillshading(
                  minZoom, maxZoom, magnitude, layer, always, _level);

//      if (this.categories == null || category == null || this.categories.contains(category)) {
              //hillShadings.add(hillshading);
//      }
              //print("Time ${DateTime.now().millisecondsSinceEpoch - time} after hillshading");
              break;
            } else if ("stylemenu" == element.name.toString()) {
              // TODO handle this case (Andrea)
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
      }
    }
    assert(foundElement);
  }
}
