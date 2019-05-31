import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/rendertheme/renderinstruction/area.dart';
import 'package:mapsforge_flutter/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../rendertheme/rule/rule.dart';
import '../rule/anymatcher.dart';
import '../rule/attributematcher.dart';
import '../rule/closed.dart';
import '../rule/closedmatcher.dart';
import '../rule/closedwaymatcher.dart';
import '../rule/element.dart';
import '../rule/elementmatcher.dart';
import '../rule/elementnodematcher.dart';
import '../rule/elementwaymatcher.dart';
import '../rule/keymatcher.dart';
import '../rule/linearwaymatcher.dart';
import '../rule/negativematcher.dart';
import '../rule/negativerule.dart';
import '../rule/positiverule.dart';
import '../rule/valuematcher.dart';

class RuleBuilder {
  static final _log = new Logger('RuleBuilder');

  static final String CAT = "cat";
  static final String CLOSED = "closed";
  static final String E = "e";
  static final String K = "k";

  static final Pattern SPLIT_PATTERN = ("\\|");
  static final String STRING_NEGATION = "~";
  static final String STRING_WILDCARD = "*";
  static final String V = "v";
  static final String ZOOM_MAX = "zoom-max";
  static final String ZOOM_MIN = "zoom-min";

  String cat;
  ClosedMatcher closedMatcher;
  ElementMatcher elementMatcher;
  int zoomMax;
  int zoomMin;
  Closed closed;
  Element element;
  List<String> keyList;
  String keys;
  final List<RuleBuilder> ruleBuilderStack;
  List<String> valueList;
  String values;
  final int level;

  static ClosedMatcher getClosedMatcher(Closed closed) {
    switch (closed) {
      case Closed.YES:
        return ClosedWayMatcher.INSTANCE;
      case Closed.NO:
        return LinearWayMatcher.INSTANCE;
      case Closed.ANY:
        return AnyMatcher.INSTANCE;
    }

    throw new Exception("unknown closed value: " + closed.toString());
  }

  static ElementMatcher getElementMatcher(Element element) {
    switch (element) {
      case Element.NODE:
        return ElementNodeMatcher.INSTANCE;
      case Element.WAY:
        return ElementWayMatcher.INSTANCE;
      case Element.ANY:
        return AnyMatcher.INSTANCE;
    }

    throw new Exception("unknown element value: " + element.toString());
  }

  static AttributeMatcher getKeyMatcher(List<String> keyList) {
    if (STRING_WILDCARD == (keyList.elementAt(0))) {
      return AnyMatcher.INSTANCE;
    }

    AttributeMatcher attributeMatcher = Rule.MATCHERS_CACHE_KEY[keyList];
    if (attributeMatcher == null) {
      attributeMatcher = new KeyMatcher(keyList);
      Rule.MATCHERS_CACHE_KEY[keyList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  static AttributeMatcher getValueMatcher(List<String> valueList) {
    if (STRING_WILDCARD == (valueList.elementAt(0))) {
      return AnyMatcher.INSTANCE;
    }

    AttributeMatcher attributeMatcher = Rule.MATCHERS_CACHE_VALUE[valueList];
    if (attributeMatcher == null) {
      attributeMatcher = new ValueMatcher(valueList);
      Rule.MATCHERS_CACHE_VALUE[valueList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  RuleBuilder(this.level) : ruleBuilderStack = List() {
    this.closed = Closed.ANY;
    this.zoomMin = 0;
    this.zoomMax = 65536;
  }

  /**
   * @return a new {@code Rule} instance.
   */
  Rule build() {
    if (this.valueList.remove(STRING_NEGATION)) {
      AttributeMatcher attributeMatcher =
          new NegativeMatcher(this.keyList, this.valueList);
      return new NegativeRule(this, attributeMatcher);
    }

    AttributeMatcher keyMatcher = getKeyMatcher(this.keyList);
    AttributeMatcher valueMatcher = getValueMatcher(this.valueList);

//    keyMatcher = RuleOptimizer.optimize(keyMatcher, this.ruleStack);
//    valueMatcher = RuleOptimizer.optimize(valueMatcher, this.ruleStack);

    return new PositiveRule(this, keyMatcher, valueMatcher);
  }

  void parse(XmlNode rootElement) {
    rootElement.attributes.forEach((XmlAttribute attribute) {
      String name = attribute.name.toString();
      String value = attribute.value;
      //_log.info("checking $name=$value");
      if (E == name) {
        this.element = Element.values
            .firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (K == name) {
        this.keys = value;
      } else if (V == name) {
        this.values = value;
      } else if (CAT == name) {
        this.cat = value;
      } else if (CLOSED == name) {
        this.closed = Closed.values
            .firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (ZOOM_MIN == name) {
        this.zoomMin = XmlUtils.parseNonNegativeByte(name, value);
      } else if (ZOOM_MAX == name) {
        this.zoomMax = XmlUtils.parseNonNegativeByte(name, value);
      } else {
        throw Exception("Invalid $name = $value in rule");
      }
    });

    validate(rootElement.toString());

    this.keyList = this.keys.split(SPLIT_PATTERN);
//        new List<String>(Arrays.asList(SPLIT_PATTERN.split(this.keys)));
//
    this.valueList = this.values.split(SPLIT_PATTERN);

    this.elementMatcher = getElementMatcher(this.element);

    this.closedMatcher = getClosedMatcher(this.closed);

//    this.elementMatcher =
//        RuleOptimizer.optimize(this.elementMatcher, this.ruleStack);
//
//    this.closedMatcher =
//        RuleOptimizer.optimize(this.closedMatcher, this.ruleStack);

    rootElement.children.forEach((node) {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          return;
        case XmlNodeType.PROCESSING:
          return;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node;
            _parseSubElement(element);
            break;
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

  void validate(String elementName) {
    XmlUtils.checkMandatoryAttribute(elementName, E, this.element);

    XmlUtils.checkMandatoryAttribute(elementName, K, this.keys);

    XmlUtils.checkMandatoryAttribute(elementName, V, this.values);

    if (this.zoomMin > this.zoomMax) {
      throw new Exception(
          '\'' + ZOOM_MIN + "' > '" + ZOOM_MAX + "': $zoomMin $zoomMax");
    }
  }

  void _parseSubElement(XmlElement rootElement) {
    String qName = rootElement.name.toString();

    if ("rule" == qName) {
      checkState(qName, XmlElementType.RULE);
      RuleBuilder ruleBuilder = RuleBuilder(level + 1);
      ruleBuilder.parse(rootElement);
      ruleBuilderStack.add(ruleBuilder);
//      Rule rule = new RuleBuilder(qName, pullParser, this.ruleStack).build();
//      if (!this.ruleStack.empty() && isVisible(rule)) {
//        this.currentRule.addSubRule(rule);
//      }
//      this.currentRule = rule;
//      this.ruleStack.push(this.currentRule);
    } else if ("area" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      Area area = new Area(null, null, qName, level + 1, null);
      area.parse(rootElement);
//      if (isVisible(area)) {
//        this.currentRule.addRenderingInstruction(area);
//      }
    } else if ("caption" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//      Caption caption = new Caption(
//          this.graphicFactory, this.displayModel, qName, pullParser, symbols);
//      if (isVisible(caption)) {
//        this.currentRule.addRenderingInstruction(caption);
//      }
    } else if ("cat" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
      //this.currentLayer.addCategory(getStringAttribute("id"));
    } else if ("circle" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//      Circle circle = new Circle(
//          this.graphicFactory, this.displayModel, qName, pullParser,
//          this.level++);
//      if (isVisible(circle)) {
//        this.currentRule.addRenderingInstruction(circle);
//      }
    }

// rendertheme menu layer
    else if ("layer" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
      bool enabled = false;
//      if (getStringAttribute("enabled") != null) {
//        enabled = getStringAttribute("enabled") == "true";
//      }
//      bool visible = getStringAttribute("visible") == "true";
//      this.currentLayer = this
//          .renderThemeStyleMenu
//          .createLayer(getStringAttribute("id"), visible, enabled);
//      String parent = getStringAttribute("parent");
//      if (null != parent) {
//        XmlRenderThemeStyleLayer parentEntry =
//            this.renderThemeStyleMenu.getLayer(parent);
//        if (null != parentEntry) {
//          for (String cat in parentEntry.getCategories()) {
//            this.currentLayer.addCategory(cat);
//          }
//          for (XmlRenderThemeStyleLayer overlay in parentEntry.getOverlays()) {
//            this.currentLayer.addOverlay(overlay);
//          }
//        }
//      }
    } else if ("line" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//    Line line = new Line(this.graphicFactory, this.displayModel, qName, pullParser, this.level++,
//    this.relativePathPrefix);
//    if (isVisible(line)) {
//    this.currentRule.addRenderingInstruction(line);
//    }
    } else if ("lineSymbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//    LineSymbol lineSymbol = new LineSymbol(this.graphicFactory, this.displayModel, qName,
//    pullParser, this.relativePathPrefix);
//    if (isVisible(lineSymbol)) {
//    this.currentRule.addRenderingInstruction(lineSymbol);
//    }
    }

// render theme menu name
    else if ("name" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
//      this.currentLayer.addTranslation(
//          getStringAttribute("lang"), getStringAttribute("value"));
    }

// render theme menu overlay
    else if ("overlay" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
//      XmlRenderThemeStyleLayer overlay =
//          this.renderThemeStyleMenu.getLayer(getStringAttribute("id"));
//      if (overlay != null) {
//        this.currentLayer.addOverlay(overlay);
//      }
    } else if ("pathText" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//      PathText pathText = new PathText(
//          this.graphicFactory, this.displayModel, qName, pullParser);
//      if (isVisible(pathText)) {
//        this.currentRule.addRenderingInstruction(pathText);
//      }
    } else if ("stylemenu" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);

//      this.renderThemeStyleMenu = new XmlRenderThemeStyleMenu(
//          getStringAttribute("id"),
//          getStringAttribute("defaultlang"),
//          getStringAttribute("defaultvalue"));
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
//      Symbol symbol = new Symbol(
//          this.graphicFactory, this.displayModel, qName, pullParser,
//          this.relativePathPrefix);
//      if (isVisible(symbol)) {
//        this.currentRule.addRenderingInstruction(symbol);
//      }
//      String symbolId = symbol.getId();
//      if (symbolId != null) {
//        this.symbols.put(symbolId, symbol);
//      }
    } else if ("hillshading" == qName) {
      checkState(qName, XmlElementType.RULE);
      String category = null;
      int minZoom = 5;
      int maxZoom = 17;
      int layer = 5;
      int magnitude = 64;
      bool always = false;

//      for (int i = 0; i < pullParser.getAttributeCount(); ++i) {
//        String name = pullParser.getAttributeName(i);
//        String value = pullParser.getAttributeValue(i);
//
//        if ("cat" == name)
//    ) {
//    category = value;
//    } else if ("zoom-min" == name) {
//    minZoom = XmlUtils.parseNonNegativeByte("zoom-min", value);
//    } else if ("zoom-max" == name) {
//    maxZoom = XmlUtils.parseNonNegativeByte("zoom-max", value);
//    } else if ("magnitude" == name) {
//    magnitude = (short) XmlUtils.parseNonNegativeInteger("magnitude", value);
//    if (magnitude > 255)
//    throw new Exception("Attribute 'magnitude' must not be > 255");
//    } else if ("always" == name) {
//    always = Boolean.valueOf(value);
//    } else if ("layer" == name) {
//    layer = XmlUtils.parseNonNegativeByte("layer", value);
//    }
//    }

//      int hillShadingLevel = this.level++;
//    Hillshading hillshading = new Hillshading(minZoom, maxZoom, magnitude, layer, always, hillShadingLevel, this.graphicFactory);

//      if (this.categories == null ||
//          category == null ||
//          this.categories.contains(category)) {
//        //      this.renderTheme.addHillShadings(hillshading);
//      }
    } else {
      throw new Exception(
          "unknown element: " + qName + ", " + rootElement.toString());
    }
  }

  void checkElement(String elementName, XmlElementType element) {
    switch (element) {
      case XmlElementType.RENDER_THEME:
//        if (!this.elementStack.isEmpty) {
//          throw new Exception(UNEXPECTED_ELEMENT + elementName);
//        }
        return;

      case XmlElementType.RULE:
//        Element parentElement = this.elementStack.peek();
//        if (parentElement != Element.RENDER_THEME &&
//            parentElement != Element.RULE) {
//          throw new Exception(UNEXPECTED_ELEMENT + elementName);
//        }
        return;

      case XmlElementType.RENDERING_INSTRUCTION:
//        if (this.elementStack.peek() != Element.RULE) {
//          throw new Exception(UNEXPECTED_ELEMENT + elementName);
//        }
        return;

      case XmlElementType.RENDERING_STYLE:
        return;
    }

    throw new Exception("unknown enum value: " + element.toString());
  }

  void checkState(String elementName, XmlElementType element) {
    checkElement(elementName, element);
//    this.elementStack.push(element);
  }
}

/////////////////////////////////////////////////////////////////////////////

enum XmlElementType {
  RENDER_THEME,
  RENDERING_INSTRUCTION,
  RULE,
  RENDERING_STYLE,
}
