import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/hillshading.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';
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

  final GraphicFactory graphicFactory;
  final DisplayModel displayModel;
  double baseStrokeWidth;
  double baseTextSize;
  bool hasBackgroundOutside;
  int mapBackground;
  int mapBackgroundOutside;
  int version;
  final List<RuleBuilder> ruleBuilderStack = List();
  int level = 0;
  List<RenderInstruction> initPendings = List();

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
    assert(ruleBuilderStack.length > 0);
    RenderTheme renderTheme = RenderTheme(this);
    ruleBuilderStack.forEach((ruleBuilder) {
      Rule rule = ruleBuilder.build();
      assert(rule != null);
      renderTheme.addRule(rule);
    });
    renderTheme.setLevels(level);
    renderTheme.initPendings = initPendings;
    return renderTheme;
  }

  ///
  /// Parses a given xml string and creates the renderinstruction-structure. The renderinstruction classes serves two purposes:
  /// On the one hand to parse the xml and create the tree structure and on the other hand to render ways and pois
  /// appropriately and draw the respective content.
  ///
  void parseXml(String content) {
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
            XmlElement element = node;
            if (element.name.toString() != "rendertheme") throw Exception("Invalid root node ${element.name.toString()}");
            foundRendertheme = true;
            _parseRendertheme(element, initPendings);
            break;
          }
        case XmlNodeType.ATTRIBUTE:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.COMMENT:
          // throw Exception("Invalid node ${node.nodeType.toString()}");
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
    }
    assert(foundRendertheme);
    _log.info("Found ${initPendings.length} items for lazy initialization");
  }

  void _parseRendertheme(XmlElement rootElement, List<RenderInstruction> initPendings) {
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
            XmlElement element = node;
            foundElement = true;
            if (element.name.toString() == "rule") {
              RuleBuilder ruleBuilder = RuleBuilder(graphicFactory, displayModel, Map<String, RenderSymbol>(), level++);
              ruleBuilder.parse(element, initPendings);
              level = ruleBuilder.level;
              ruleBuilderStack.add(ruleBuilder);
              foundRule = true;
              //print("Time ${DateTime.now().millisecondsSinceEpoch - time} after rule ${element.toString()}");
              break;
            } else if ("hillshading" == element.name.toString()) {
              String category = null;
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
                  magnitude = XmlUtils.parseNonNegativeInteger("magnitude", value).toDouble();
                  if (magnitude > 255) throw new Exception("Attribute 'magnitude' must not be > 255");
                } else if ("always" == name) {
                  always = "true" == (value);
                } else if ("layer" == name) {
                  layer = XmlUtils.parseNonNegativeByte("layer", value);
                }
              });

              Hillshading hillshading = new Hillshading(minZoom, maxZoom, magnitude, layer, always, level++);

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
          break;
        case XmlNodeType.CDATA:
          throw Exception("Invalid node ${node.nodeType.toString()}");
          break;
        case XmlNodeType.COMMENT:
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
    }
    assert(foundElement);
  }
}
