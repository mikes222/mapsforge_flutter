import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/model/displaymodel.dart';
import 'package:mapsforge_flutter/rendertheme/xml/xmlutils.dart';
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

  final GraphicFactory graphicFactory;
  final DisplayModel displayModel;
  double baseStrokeWidth;
  double baseTextSize;
  bool hasBackgroundOutside;
  int mapBackground;
  int mapBackgroundOutside;
  int version;
  final List<RuleBuilder> ruleBuilderStack = List();

  RenderThemeBuilder(this.graphicFactory, this.displayModel)
      : assert(graphicFactory != null),
        assert(displayModel != null) {
    this.baseStrokeWidth = 1;
    this.baseTextSize = 1;
//    this.mapBackground = graphicFactory.createColor(Color.WHITE);
  }

  /**
   * @return a new {@code RenderTheme} instance.
   */
  RenderTheme build() {
    RenderTheme renderTheme = RenderTheme(this);
    int maxLevel = 0;
    ruleBuilderStack.forEach((ruleBuilder) {
      _log.info("rule: " + ruleBuilder.build().toString());
      renderTheme.addRule(ruleBuilder.build());
      if (maxLevel < ruleBuilder.getMaxLevel()) maxLevel = ruleBuilder.getMaxLevel();
    });
    renderTheme.setLevels(maxLevel);
    return renderTheme;
  }

  void parseXml(String content) {
    XmlDocument document = parse(content);
    document.children.forEach((node) {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          return;
        case XmlNodeType.PROCESSING:
          return;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node;
            if (element.name.toString() != "rendertheme") throw Exception("Invalid root node ${element.name.toString()}");
            _parseRendertheme(element);
            return;
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.COMMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT_FRAGMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT_TYPE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
      }
    });
  }

  void _parseRendertheme(XmlElement rootElement) {
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
    rootElement.children.forEach((node) {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          return;
        case XmlNodeType.PROCESSING:
          return;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node;
            if (element.name.toString() == "rule") {
              RuleBuilder ruleBuilder = RuleBuilder(graphicFactory, displayModel, 0);
              ruleBuilder.parse(element);
              ruleBuilderStack.add(ruleBuilder);
              return;
            }
            throw Exception("Invalid root node ${element.name.toString()}");
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.COMMENT:
          return;
        case XmlNodeType.DOCUMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT_FRAGMENT:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.DOCUMENT_TYPE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
      }
    });
  }

  void _parseRule(XmlElement rootElement) {}
}
