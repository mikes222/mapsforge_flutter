import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_area.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_hillshading.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_line.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_linesymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction_symbol.dart';
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
import '../shape/shape_symbol.dart';

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

  int level;
  int maxLevel;

  String? cat;
  ClosedMatcher? closedMatcher;
  ElementMatcher? elementMatcher;
  int zoomMax;
  int zoomMin;
  Closed? closed;
  Element? element;
  final List<String> keyList = [];
  String? keys;
  final List<RenderInstruction>
      renderInstructions; // NOSONAR NOPMD we need specific interface
  final List<RuleBuilder> ruleBuilderStack;
  final SymbolFinder symbolFinder;
  List<RenderinstructionHillshading> hillShadings =
      []; // NOPMD specific interface for trimToSize
  final List<String> valueList = [];
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

  RuleBuilder(SymbolFinder? parentSymbolFinder, this.level)
      : ruleBuilderStack = [],
        renderInstructions = [],
        this.zoomMin = 0,
        this.zoomMax = 65536,
        maxLevel = level,
        this.symbolFinder = SymbolFinder(parentSymbolFinder) {
    this.closed = Closed.ANY;
  }

  void validateTree() {
    for (RuleBuilder ruleBuilder in ruleBuilderStack) {
      if (element == Element.NODE && ruleBuilder.element == Element.WAY) {
        _log.warning(
            "Impossible SubRule which has element way (${ruleBuilder.element}) whereas the parent has element node ($element)");
      }
      if (element == Element.WAY && ruleBuilder.element == Element.NODE) {
        _log.warning(
            "Impossible SubRule which has element node (${ruleBuilder}) whereas the parent has element way ($this)");
      }
      if (zoomMax < ruleBuilder.zoomMin) {
        _log.warning(
            "Impossible SubZoomMin ${ruleBuilder.zoomMin} whereas the parent has zoomMax $zoomMax");
      }
      if (zoomMin > ruleBuilder.zoomMax) {
        _log.warning(
            "Impossible SubZoomMax ${ruleBuilder.zoomMax} whereas the parent has zoomMin $zoomMin");
      }
      // List additional = ruleBuilder.keyList
      //     .where((element) => !keyList.contains(element))
      //     .toList();
      // if (additional.length > 0) {
      //   _log.warning(
      //       "Unexpected SubKeys $additional whereas parent has $keyList");
      // }
    }
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

    keyMatcher = RuleOptimizer.optimize(keyMatcher, this.ruleBuilderStack);
    valueMatcher = RuleOptimizer.optimize(valueMatcher, this.ruleBuilderStack);

    return PositiveRule(this, keyMatcher, valueMatcher);
  }

  void parse(DisplayModel displayModel, XmlNode rootElement) {
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

    this.keyList.addAll(this.keys!.split(SPLIT_PATTERN));
//        new List<String>(Arrays.asList(SPLIT_PATTERN.split(this.keys)));
//
    this.valueList.addAll(this.values!.split(SPLIT_PATTERN));

    this.elementMatcher = getElementMatcher(this.element!);

    this.closedMatcher = getClosedMatcher(this.closed!);

    this.elementMatcher = RuleOptimizer.optimizeElementMatcher(
        this.elementMatcher!, this.ruleBuilderStack);

    this.closedMatcher = RuleOptimizer.optimizeClosedMatcher(
        this.closedMatcher!, this.ruleBuilderStack);

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
            _parseSubElement(displayModel, element);
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
      throw new Exception(
          '\'' + ZOOM_MIN + "' > '" + ZOOM_MAX + "': $zoomMin $zoomMax");
    }
  }

  void _parseSubElement(DisplayModel displayModel, XmlElement rootElement) {
    String qName = rootElement.name.toString();

    if ("rule" == qName) {
      checkState(qName, XmlElementType.RULE);
      RuleBuilder ruleBuilder = RuleBuilder(symbolFinder, ++level);
      ruleBuilder.parse(displayModel, rootElement);
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
      RenderinstructionArea area = new RenderinstructionArea(level);
      area.parse(displayModel, rootElement);
      if (isVisible(area)) {
        this.addRenderingInstruction(area);
        maxLevel = max(maxLevel, level);
      }
    } else if ("caption" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionCaption caption =
          new RenderinstructionCaption(symbolFinder, level);
      caption.parse(displayModel, rootElement);
      if (isVisible(caption)) {
        this.addRenderingInstruction(caption);
//        maxLevel = max(maxLevel, level);
      }
    } else if ("cat" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
      //this.currentLayer.addCategory(getStringAttribute("id"));
    } else if ("circle" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionCircle circle = new RenderinstructionCircle(level);
      circle.parse(displayModel, rootElement);
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
      RenderinstructionLine line = new RenderinstructionLine(level);
      line.parse(displayModel, rootElement);
      if (isVisible(line)) {
        this.addRenderingInstruction(line);
        maxLevel = max(maxLevel, level);
      }
    } else if ("lineSymbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionLinesymbol lineSymbol =
          new RenderinstructionLinesymbol(level);
      lineSymbol.parse(displayModel, rootElement);
      if (isVisible(lineSymbol)) {
        this.addRenderingInstruction(lineSymbol);
        //maxLevel = max(maxLevel, level);
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
      RenderinstructionPathtext pathText = new RenderinstructionPathtext(level);
      pathText.parse(displayModel, rootElement);
      if (isVisible(pathText)) {
        this.addRenderingInstruction(pathText);
        //maxLevel = max(maxLevel, level);
      }
    } else if ("stylemenu" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);

//      this.renderThemeStyleMenu = new XmlRenderThemeStyleMenu(
//          getStringAttribute("id"),
//          getStringAttribute("defaultlang"),
//          getStringAttribute("defaultvalue"));
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionSymbol symbol =
          new RenderinstructionSymbol(symbolFinder, level);
      symbol.parse(displayModel, rootElement);
      if (isVisible(symbol)) {
        this.addRenderingInstruction(symbol);
        //maxLevel = max(maxLevel, level);
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
          magnitude =
              XmlUtils.parseNonNegativeInteger("magnitude", value).toDouble();
          if (magnitude > 255)
            throw new Exception("Attribute 'magnitude' must not be > 255");
        } else if ("always" == name) {
          always = "true" == (value);
        } else if ("layer" == name) {
          layer = XmlUtils.parseNonNegativeByte("layer", value);
        }
      });

      RenderinstructionHillshading hillshading =
          new RenderinstructionHillshading(
              minZoom, maxZoom, magnitude, layer, always, this.level);
      maxLevel = max(maxLevel, level);

//      if (this.categories == null || category == null || this.categories.contains(category)) {
      hillShadings.add(hillshading);
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

  @override
  String toString() {
    return 'RuleBuilder{zoomMax: $zoomMax, zoomMin: $zoomMin, element: $element, keys: $keys, renderInstructions: $renderInstructions, values: $values}';
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

  // map of symbolIds contains a map of zoomLevels
  final Map<String, Map<int, SymbolHolder>> _symbols = {};

  SymbolFinder(this.parentSymbolFinder);

  void add(String symbolId, int zoomLevel, ShapeSymbol shapeSymbol) {
    if (!_symbols.containsKey(symbolId)) {
      _symbols[symbolId] = {};
    }
    Map<int, SymbolHolder> holders = _symbols[symbolId]!;
    if (!holders.containsKey(zoomLevel)) {
      holders[zoomLevel] = SymbolHolder();
    }
    holders[zoomLevel]!.shapeSymbol = shapeSymbol;
  }

  SymbolHolder? search(String symbolId, int zoomLevel) {
    if (_symbols.containsKey(symbolId)) {
      Map<int, SymbolHolder> holders = _symbols[symbolId]!;
      if (holders.containsKey(zoomLevel)) {
        return holders[zoomLevel];
      }
    }
    return parentSymbolFinder?.search(symbolId, zoomLevel);
  }

  SymbolHolder findSymbolHolder(String symbolId, int zoomLevel) {
    SymbolHolder? result = search(symbolId, zoomLevel);
    if (result != null) return result;

    if (!_symbols.containsKey(symbolId)) {
      _symbols[symbolId] = {};
    }
    Map<int, SymbolHolder> holders = _symbols[symbolId]!;
    if (!holders.containsKey(zoomLevel)) {
      holders[zoomLevel] = SymbolHolder();
    }
    return holders[zoomLevel]!;
  }
}

/////////////////////////////////////////////////////////////////////////////

class SymbolHolder {
  ShapeSymbol? shapeSymbol;

  @override
  String toString() {
    return 'SymbolHolder{shapeSymbol: $shapeSymbol}';
  }
}
