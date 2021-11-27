import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/area.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/hillshading.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/line.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/linesymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendercircle.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/ruleoptimizer.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
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

  static final Pattern SPLIT_PATTERN = ("|");
  static final String STRING_NEGATION = "~";
  static final String STRING_WILDCARD = "*";
  static final String V = "v";
  static final String ZOOM_MAX = "zoom-max";
  static final String ZOOM_MIN = "zoom-min";

  final GraphicFactory graphicFactory;
  final SymbolCache symbolCache;
  final DisplayModel displayModel;
  int level;
  int maxLevel;

  String? cat;
  ClosedMatcher? closedMatcher;
  ElementMatcher? elementMatcher;
  int zoomMax;
  int zoomMin;
  Closed? closed;
  Element? element;
  List<String>? keyList;
  String? keys;
  final List<RenderInstruction> renderInstructions; // NOSONAR NOPMD we need specific interface
  final List<RuleBuilder> ruleBuilderStack;
  final SymbolFinder symbolFinder;
  List<Hillshading> hillShadings = []; // NOPMD specific interface for trimToSize
  List<String>? valueList;
  String? values;

  static ClosedMatcher getClosedMatcher(Closed closed) {
    switch (closed) {
      case Closed.YES:
        return ClosedWayMatcher.INSTANCE;
      case Closed.NO:
        return LinearWayMatcher.INSTANCE;
      case Closed.ANY:
        return AnyMatcher.INSTANCE;
    }

    //throw new Exception("unknown closed value: " + closed.toString());
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

    //throw new Exception("unknown element value: " + element.toString());
  }

  static AttributeMatcher getKeyMatcher(List<String> keyList) {
    if (STRING_WILDCARD == (keyList.elementAt(0))) {
      return AnyMatcher.INSTANCE;
    }

    AttributeMatcher? attributeMatcher = Rule.MATCHERS_CACHE_KEY[keyList];
    if (attributeMatcher == null) {
      attributeMatcher = new KeyMatcher(keyList);
      Rule.MATCHERS_CACHE_KEY[keyList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  static AttributeMatcher getValueMatcher(List<String> valueList) {
    if (valueList.length > 0 && STRING_WILDCARD == (valueList[0])) {
      return AnyMatcher.INSTANCE;
    }

    AttributeMatcher? attributeMatcher = Rule.MATCHERS_CACHE_VALUE[valueList];
    if (attributeMatcher == null) {
      attributeMatcher = new ValueMatcher(valueList);
      Rule.MATCHERS_CACHE_VALUE[valueList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  RuleBuilder(this.graphicFactory, this.symbolCache, this.displayModel, SymbolFinder? parentSymbolFinder,
      List<RenderInstruction> initPendings, this.level)
      : ruleBuilderStack = [],
        renderInstructions = [],
        this.zoomMin = 0,
        this.zoomMax = 65536,
        maxLevel = level,
        this.symbolFinder = SymbolFinder(parentSymbolFinder, initPendings, graphicFactory) {
    this.closed = Closed.ANY;
  }

  /**
   * @return a new {@code Rule} instance.
   */
  Rule build() {
    if (this.valueList!.remove(STRING_NEGATION)) {
      AttributeMatcher attributeMatcher = new NegativeMatcher(this.keyList!, this.valueList!);
      return new NegativeRule(this, attributeMatcher);
    }

    AttributeMatcher keyMatcher = getKeyMatcher(this.keyList!);
    AttributeMatcher valueMatcher = getValueMatcher(this.valueList!);

    keyMatcher = RuleOptimizer.optimize(keyMatcher, this.ruleBuilderStack);
    valueMatcher = RuleOptimizer.optimize(valueMatcher, this.ruleBuilderStack);

    return PositiveRule(this, keyMatcher, valueMatcher);
  }

  void parse(XmlNode rootElement, List<RenderInstruction> initPendings) {
    rootElement.attributes.forEach((XmlAttribute attribute) {
      String name = attribute.name.toString();
      String value = attribute.value;
      //_log.info("checking $name=$value");
      if (E == name) {
        this.element = Element.values.firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (K == name) {
        this.keys = value;
      } else if (V == name) {
        this.values = value;
      } else if (CAT == name) {
        this.cat = value;
      } else if (CLOSED == name) {
        this.closed = Closed.values.firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (ZOOM_MIN == name) {
        this.zoomMin = XmlUtils.parseNonNegativeByte(name, value);
      } else if (ZOOM_MAX == name) {
        this.zoomMax = XmlUtils.parseNonNegativeByte(name, value);
      } else {
        throw Exception("Invalid $name = $value in rule");
      }
    });

    validate(rootElement.toString());

    this.keyList = this.keys!.split(SPLIT_PATTERN);
//        new List<String>(Arrays.asList(SPLIT_PATTERN.split(this.keys)));
//
    this.valueList = this.values!.split(SPLIT_PATTERN);

    this.elementMatcher = getElementMatcher(this.element!);

    this.closedMatcher = getClosedMatcher(this.closed!);

    this.elementMatcher = RuleOptimizer.optimizeElementMatcher(this.elementMatcher!, this.ruleBuilderStack);

    this.closedMatcher = RuleOptimizer.optimizeClosedMatcher(this.closedMatcher!, this.ruleBuilderStack);

    for (XmlNode node in rootElement.children) {
      //rootElement.children.forEach((node) async {
      switch (node.nodeType) {
        case XmlNodeType.TEXT:
          break;
        case XmlNodeType.PROCESSING:
          break;
        case XmlNodeType.ELEMENT:
          {
            XmlElement element = node as XmlElement;
            _parseSubElement(element, initPendings);
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
      }
    }
  }

  void validate(String elementName) {
    XmlUtils.checkMandatoryAttribute(elementName, E, this.element);

    XmlUtils.checkMandatoryAttribute(elementName, K, this.keys);

    XmlUtils.checkMandatoryAttribute(elementName, V, this.values);

    if (this.zoomMin > this.zoomMax) {
      throw new Exception('\'' + ZOOM_MIN + "' > '" + ZOOM_MAX + "': $zoomMin $zoomMax");
    }
  }

  void _parseSubElement(XmlElement rootElement, List<RenderInstruction> initPendings) {
    String qName = rootElement.name.toString();

    if ("rule" == qName) {
      checkState(qName, XmlElementType.RULE);
      RuleBuilder ruleBuilder = RuleBuilder(graphicFactory, symbolCache, displayModel, symbolFinder, initPendings, ++level);
      ruleBuilder.parse(rootElement, initPendings);
      ruleBuilderStack.add(ruleBuilder);
      maxLevel = max(level, ruleBuilder.maxLevel);
//      Rule rule = new RuleBuilder(qName, pullParser, this.ruleStack).build();
//      if (!this.ruleStack.empty() && isVisible(rule)) {
//        this.currentRule.addSubRule(rule);
//      }
//      this.currentRule = rule;
//      this.ruleStack.push(this.currentRule);
    } else if ("area" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      Area area = new Area(graphicFactory, symbolCache, displayModel, qName, level);
      area.parse(rootElement, initPendings);
      if (isVisible(area)) {
        this.addRenderingInstruction(area);
        maxLevel = max(maxLevel, level);
      }
    } else if ("caption" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      Caption caption = new Caption(this.graphicFactory, this.displayModel, symbolFinder);
      caption.parse(rootElement, initPendings);
      if (isVisible(caption)) {
        this.addRenderingInstruction(caption);
      }
    } else if ("cat" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
      //this.currentLayer.addCategory(getStringAttribute("id"));
    } else if ("circle" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderCircle circle = new RenderCircle(this.graphicFactory, this.displayModel, level);
      circle.parse(rootElement, initPendings);
      if (isVisible(circle)) {
        this.addRenderingInstruction(circle);
        maxLevel = max(maxLevel, level);
      }
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
      Line line = new Line(this.graphicFactory, symbolCache, this.displayModel, qName, level, null);
      line.parse(rootElement, initPendings);
      if (isVisible(line)) {
        this.addRenderingInstruction(line);
        maxLevel = max(maxLevel, level);
      }
    } else if ("lineSymbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      LineSymbol lineSymbol = new LineSymbol(this.graphicFactory, this.symbolCache, this.displayModel, null);
      lineSymbol.parse(rootElement, initPendings);
      if (isVisible(lineSymbol)) {
        this.addRenderingInstruction(lineSymbol);
      }
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
      PathText pathText = new PathText(this.graphicFactory, this.displayModel);
      pathText.parse(rootElement, initPendings);
      if (isVisible(pathText)) {
        this.addRenderingInstruction(pathText);
      }
    } else if ("stylemenu" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);

//      this.renderThemeStyleMenu = new XmlRenderThemeStyleMenu(
//          getStringAttribute("id"),
//          getStringAttribute("defaultlang"),
//          getStringAttribute("defaultvalue"));
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderSymbol symbol = new RenderSymbol(this.graphicFactory, this.symbolCache, this.displayModel);
      symbol.parse(rootElement, initPendings);
      if (isVisible(symbol)) {
        this.addRenderingInstruction(symbol);
      }
      String? symbolId = symbol.getId();
      if (symbolId != null) {
        symbolFinder.add(symbolId, symbol);
      }
    } else if ("hillshading" == qName) {
      checkState(qName, XmlElementType.RULE);
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
          magnitude = XmlUtils.parseNonNegativeInteger("magnitude", value).toDouble();
          if (magnitude > 255) throw new Exception("Attribute 'magnitude' must not be > 255");
        } else if ("always" == name) {
          always = "true" == (value);
        } else if ("layer" == name) {
          layer = XmlUtils.parseNonNegativeByte("layer", value);
        }
      });

      Hillshading hillshading = new Hillshading(minZoom, maxZoom, magnitude, layer, always, this.level);
      maxLevel = max(maxLevel, level);

//      if (this.categories == null || category == null || this.categories.contains(category)) {
      hillShadings.add(hillshading);
//      }
    } else {
      throw new Exception("unknown element: " + qName + ", " + rootElement.toString());
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

    //throw new Exception("unknown enum value: " + element.toString());
  }

  void checkState(String elementName, XmlElementType element) {
    checkElement(elementName, element);
//    this.elementStack.push(element);
  }

  bool isVisible(RenderInstruction renderInstruction) {
    return true;
    //return this.categories == null || renderInstruction.getCategory() == null || this.categories.contains(renderInstruction.getCategory());
  }

  bool isVisibleRule(Rule rule) {
    // a rule is visible if categories is not set, the rule has not category or the
    // categories contain this rule's category
    return true;
    //return this.categories == null || rule.cat == null || this.categories.contains(rule.cat);
  }

  void addRenderingInstruction(RenderInstruction renderInstruction) {
    this.renderInstructions.add(renderInstruction);
  }
}

/////////////////////////////////////////////////////////////////////////////

enum XmlElementType {
  RENDER_THEME,
  RENDERING_INSTRUCTION,
  RULE,
  RENDERING_STYLE,
}

/////////////////////////////////////////////////////////////////////////////

class SymbolFinder {
  final SymbolFinder? parentSymbolFinder;

  final Map<String, RenderSymbol> _symbols = Map();

  final List<RenderInstruction> initPendings;

  final GraphicFactory graphicFactory;

  SymbolFinder(this.parentSymbolFinder, this.initPendings, this.graphicFactory);

  void add(String symbolId, RenderSymbol renderSymbol) {
    assert(!_symbols.containsKey(symbolId));
    _symbols[symbolId] = renderSymbol;
  }

  Future<RenderSymbol?> find(String symbolId) async {
    RenderSymbol? result = _symbols[symbolId];
    if (result != null) {
      if (initPendings.contains(result)) {
        await result.initResources(graphicFactory);
        initPendings.remove(result);
      }
      return result;
    }
    if (parentSymbolFinder == null) return null;
    return parentSymbolFinder!.find(symbolId);
  }
}
