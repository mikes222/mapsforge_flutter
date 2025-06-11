import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/ruleoptimizer.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_area.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_hillshading.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_linesymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_polyline.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_symbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/symbol_finder.dart';
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
import '../rule/linearwaymatcher.dart';
import '../rule/negativematcher.dart';
import '../rule/negativerule.dart';
import '../rule/positiverule.dart';

class RuleBuilder {
  static final _log = new Logger('RuleBuilder');

  static final String CAT = "cat";
  static final String CLOSED = "closed";
  static final String E = "e";
  static final String K = "k";
  static final String ID = "id";

  static final Pattern SPLIT_PATTERN = ("|");
  static final String STRING_NEGATION = "~";
  static final String STRING_WILDCARD = "*";
  static final String V = "v";
  static final String ZOOM_MAX = "zoom-max";
  static final String ZOOM_MIN = "zoom-min";
  final Set<String> excludeIds;
  int level;
  int maxLevel;

  String? cat;
  String? id;
  ZoomlevelRange zoomlevelRange;

  /// A boolean variable which will be set to true if this rule can never be
  /// executed. This may happen for example if the [DisplayModel] sets the
  /// max zoom size to for example 9 and the rule has a min-zoom size of 10.
  bool impossible = false;

  Closed closed = Closed.ANY;
  Element element = Element.ANY;
  String? keys;
  final List<RenderInstructionNode> renderInstructionNodes;
  final List<RenderInstructionWay> renderInstructionOpenWays;
  final List<RenderInstructionWay> renderInstructionClosedWays;

  // rules directly below this rule
  final List<RuleBuilder> ruleBuilderStack;

  /// a finder for symbols. See for example "bus-stop" in the defaultrender.xml. Each
  /// finder has a nullable parent-symbolFinder attached which in fact represents
  /// the tree-structure of the xml-file or this rules.
  final ZoomlevelSymbolFinder zoomlevelSymbolFinder;

  List<RenderinstructionHillshading> hillShadings = []; // NOPMD specific interface for trimToSize
  String? values;

  late AttributeMatcher keyMatcher;
  late AttributeMatcher valueMatcher;
  NegativeMatcher? negativeMatcher;

  ClosedMatcher getClosedMatcher() {
    ClosedMatcher result;
    switch (closed) {
      case Closed.YES:
        result = const ClosedWayMatcher();
      case Closed.NO:
        result = const LinearWayMatcher();
      case Closed.ANY:
        result = const AnyMatcher();
    }
    return RuleOptimizer.optimizeClosedMatcher(result, ruleBuilderStack);
  }

  ElementMatcher getElementMatcher() {
    ElementMatcher result;
    switch (element) {
      case Element.NODE:
        result = const ElementNodeMatcher();
      case Element.WAY:
        result = const ElementWayMatcher();
      case Element.ANY:
        result = const AnyMatcher();
    }
    return RuleOptimizer.optimizeElementMatcher(result, this.ruleBuilderStack);
  }

  RuleBuilder(DisplayModel displayModel, ZoomlevelSymbolFinder? parentSymbolFinder, this.level, {Set<String>? excludeIds})
      : excludeIds = excludeIds ?? {},
        zoomlevelRange = displayModel.zoomlevelRange,
        ruleBuilderStack = [],
        renderInstructionNodes = [],
        renderInstructionOpenWays = [],
        renderInstructionClosedWays = [],
        maxLevel = level,
        this.zoomlevelSymbolFinder = ZoomlevelSymbolFinder(parentSymbolFinder) {
    this.closed = Closed.ANY;
    this.element = Element.ANY;
  }

  void validateTree() {
    for (RuleBuilder ruleBuilder in ruleBuilderStack) {
      if (element == Element.NODE && ruleBuilder.element == Element.WAY) {
        _log.warning("Impossible SubRule which has element way (${ruleBuilder.element}) whereas the parent has element node ($element)");
      }
      if (element == Element.WAY && ruleBuilder.element == Element.NODE) {
        _log.warning("Impossible SubRule which has element node (${ruleBuilder}) whereas the parent has element way ($this)");
      }
      if (closed == Closed.YES && ruleBuilder.closed == Closed.NO) {
        _log.warning("Impossible SubRule which has closed no (${ruleBuilder}) whereas the parent has closed yes ($this)");
      }
      if (closed == Closed.NO && ruleBuilder.closed == Closed.YES) {
        _log.warning("Impossible SubRule which has closed yes (${ruleBuilder}) whereas the parent has closed no ($this)");
      }
      if (zoomlevelRange.zoomlevelMax < ruleBuilder.zoomlevelRange.zoomlevelMin) {
        _log.warning("Impossible SubZoomMin ${ruleBuilder.zoomlevelRange.zoomlevelMin} whereas the parent has zoomMax ${zoomlevelRange.zoomlevelMax}");
      }
      if (zoomlevelRange.zoomlevelMin > ruleBuilder.zoomlevelRange.zoomlevelMax) {
        _log.warning("Impossible SubZoomMax ${ruleBuilder.zoomlevelRange.zoomlevelMax} whereas the parent has zoomMin ${zoomlevelRange.zoomlevelMin}");
      }
    }
    // this is allowed: A rule "node" could have a "caption" which is both used for nodes and for ways
    // if (element == Element.NODE && renderInstructionWays.isNotEmpty) {
    //   _log.warning(
    //       "Impossible SubRule which has renderInstructionWays whereas the parent has element node ($this)");
    // }
    // if (element == Element.WAY && renderInstructionNodes.isNotEmpty) {
    //   _log.warning(
    //       "Impossible SubRule which has renderInstructionNodess whereas the parent has element way ($this)");
    // }
    if (element == Element.NODE && renderInstructionNodes.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionNodes whereas the parent has element node ($this)");
    }
    if (element == Element.WAY && renderInstructionOpenWays.isEmpty && renderInstructionClosedWays.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionWays whereas the parent has element way ($this)");
    }
    if (renderInstructionNodes.isEmpty && renderInstructionOpenWays.isEmpty && renderInstructionClosedWays.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionNodes or renderInstructionWays ($this)");
    }
  }

  /**
   * @return a new {@code Rule} instance.
   */
  Rule build() {
    if (negativeMatcher != null) {
      return NegativeRule(this, negativeMatcher!);
    }

    if (renderInstructionNodes.isEmpty && renderInstructionOpenWays.isEmpty && renderInstructionClosedWays.isEmpty) {
      keyMatcher = RuleOptimizer.optimize(keyMatcher, this.ruleBuilderStack);
      valueMatcher = RuleOptimizer.optimize(valueMatcher, this.ruleBuilderStack);
    }

    return PositiveRule(this, keyMatcher, valueMatcher);
  }

  void parse(DisplayModel displayModel, XmlNode rootElement) {
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
      } else if (ID == name) {
        this.id = value;
      } else if (CLOSED == name) {
        this.closed = Closed.values.firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (ZOOM_MIN == name) {
        try {
          zoomlevelRange = zoomlevelRange.restrictToMin(XmlUtils.parseNonNegativeByte(name, value));
        } catch (_) {
          impossible = true;
        }
      } else if (ZOOM_MAX == name) {
        try {
          zoomlevelRange = zoomlevelRange.restrictToMax(XmlUtils.parseNonNegativeByte(name, value));
        } catch (_) {
          impossible = true;
        }
      } else {
        throw Exception("Invalid $name = $value in rule");
      }
    });

    validate(rootElement.toString());

    List<String> keyList = this.keys!.split(SPLIT_PATTERN);
    List<String> valueList = this.values!.split(SPLIT_PATTERN);

// Always initialize keyMatcher and valueMatcher
    keyMatcher = AttributeMatcher.getKeyMatcher(keyList);
    valueMatcher = AttributeMatcher.getValueMatcher(valueList);

    if (valueList.remove(STRING_NEGATION)) {
      negativeMatcher = NegativeMatcher(keyList, valueList);
    }

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
        default:
          break;
      }
    }
  }

  void validate(String elementName) {
    XmlUtils.checkMandatoryAttribute(elementName, E, this.element);

    XmlUtils.checkMandatoryAttribute(elementName, K, this.keys);

    XmlUtils.checkMandatoryAttribute(elementName, V, this.values);

    if (zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) {
      // we cannot throw an exception. The xml file may contain a rule with zoomMin > e.g. 12 but we only allow e.g. zoomMax 9 in displayModel. The xml is NOT
      // invalid in that case
      // throw new Exception(
      //     "ZoomMin ${zoomlevelRange.zoomlevelMin} > ZoomMax ${zoomlevelRange.zoomlevelMax} for rule with $keys and $values and childs ${ruleBuilderStack.toString()}");
    }
  }

  void _parseSubElement(DisplayModel displayModel, XmlElement rootElement) {
    String qName = rootElement.name.toString();

    if ("rule" == qName) {
      String? ruleId = rootElement.getAttribute("id");
      if (ruleId != null && excludeIds.contains(ruleId)) {
        _log.info("Excluding rule with id: $ruleId");
        return; // Skip parsing this rule entirely.
      }
      checkState(qName, XmlElementType.RULE);
      RuleBuilder ruleBuilder = RuleBuilder(displayModel, zoomlevelSymbolFinder, ++level, excludeIds: this.excludeIds);
      ruleBuilder.zoomlevelRange = zoomlevelRange;

      try {
        ruleBuilder.parse(displayModel, rootElement);
      } catch (error, stacktrace) {
        _log.warning("Error while parsing rule $ruleBuilder which is a subrule of $this", error, stacktrace);
      }
      ruleBuilderStack.add(ruleBuilder);
      maxLevel = max(level, ruleBuilder.maxLevel);
    } else if ("area" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionArea area = new RenderinstructionArea(level);
      area.parse(displayModel, rootElement);
      if (isVisibleWay(area)) {
        if (closed != Closed.NO) this.addRenderingInstructionClosedWay(area);
        maxLevel = max(maxLevel, level);
      }
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionSymbol symbol = RenderinstructionSymbol(zoomlevelSymbolFinder, level);
      symbol.parse(displayModel, rootElement);
      // Skip if the symbol's id is in the excluded set.
      if (symbol.base.id != null && excludeIds.contains(symbol.base.id)) {
        _log.info("Excluding symbol with id: ${symbol.base.id}");
      } else {
        if (isVisible(symbol)) {
          if (element != Element.WAY) addRenderingInstructionNode(symbol);
          if (closed != Closed.NO) addRenderingInstructionClosedWay(symbol);
        }
      }
    } else if ("caption" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionCaption caption = new RenderinstructionCaption(zoomlevelSymbolFinder, level);
      caption.parse(displayModel, rootElement);
      if (isVisible(caption)) {
        if (element != Element.WAY) this.addRenderingInstructionNode(caption);
        if (closed != Closed.NO) this.addRenderingInstructionClosedWay(caption);
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
        if (element != Element.WAY) this.addRenderingInstructionNode(circle);
        maxLevel = max(maxLevel, level);
      }
    } else if ("line" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionPolyline line = RenderinstructionPolyline(level);

      line.parse(displayModel, rootElement);
      if (line.base.id != null && excludeIds.contains(line.base.id)) {
        _log.info("Excluding symbol with id: ${line.base.id}");
      } else {
        if (isVisibleWay(line)) {
          if (closed != Closed.YES) this.addRenderingInstructionOpenWay(line);
          if (closed != Closed.NO) this.addRenderingInstructionClosedWay(line);
          maxLevel = max(maxLevel, level);
        }
      }
    } else if ("lineSymbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionLinesymbol lineSymbol = new RenderinstructionLinesymbol(level);
      lineSymbol.parse(displayModel, rootElement);
      if (isVisibleWay(lineSymbol)) {
        if (closed != Closed.YES) this.addRenderingInstructionOpenWay(lineSymbol);
        if (closed != Closed.NO) this.addRenderingInstructionClosedWay(lineSymbol);
        //maxLevel = max(maxLevel, level);
      }
    }

// render theme menu name
    else if ("name" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
//      this.currentLayer.addTranslation(
//          getStringAttribute("lang"), getStringAttribute("value"));
    } else if ("pathText" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionPathtext pathText = new RenderinstructionPathtext(level);
      pathText.parse(displayModel, rootElement);
      if (isVisibleWay(pathText)) {
        if (closed != Closed.YES) this.addRenderingInstructionOpenWay(pathText);
        if (closed != Closed.NO) this.addRenderingInstructionClosedWay(pathText);
        //maxLevel = max(maxLevel, level);
      }
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionSymbol symbol = new RenderinstructionSymbol(zoomlevelSymbolFinder, level);
      symbol.parse(displayModel, rootElement);
      if (isVisible(symbol)) {
        if (element != Element.WAY) this.addRenderingInstructionNode(symbol);
        if (closed != Closed.NO) this.addRenderingInstructionClosedWay(symbol);
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
          magnitude = XmlUtils.parseNonNegativeInteger("magnitude", value).toDouble();
          if (magnitude > 255) throw new Exception("Attribute 'magnitude' must not be > 255");
        } else if ("always" == name) {
          always = "true" == (value);
        } else if ("layer" == name) {
          layer = XmlUtils.parseNonNegativeByte("layer", value);
        }
      });

      RenderinstructionHillshading hillshading = new RenderinstructionHillshading(minZoom, maxZoom, magnitude, layer, always, this.level);
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

  bool isVisible(RenderInstructionNode renderInstructionNode) {
    return true;
    //return this.categories == null || renderInstruction.getCategory() == null || this.categories.contains(renderInstruction.getCategory());
  }

  bool isVisibleWay(RenderInstructionWay renderInstructionWay) {
    return true;
    //return this.categories == null || renderInstruction.getCategory() == null || this.categories.contains(renderInstruction.getCategory());
  }

  bool isVisibleRule(Rule rule) {
    // a rule is visible if categories is not set, the rule has not category or the
    // categories contain this rule's category
    return true;
    //return this.categories == null || rule.cat == null || this.categories.contains(rule.cat);
  }

  void addRenderingInstructionNode(RenderInstructionNode renderInstructionNode) {
    this.renderInstructionNodes.add(renderInstructionNode);
  }

  void addRenderingInstructionOpenWay(RenderInstructionWay renderInstructionWay) {
    this.renderInstructionOpenWays.add(renderInstructionWay);
  }

  void addRenderingInstructionClosedWay(RenderInstructionWay renderInstructionWay) {
    this.renderInstructionClosedWays.add(renderInstructionWay);
  }

  @override
  String toString() {
    return 'RuleBuilder{zoomlevelRange: $zoomlevelRange, element: $element, keys: $keys, renderInstructionNodes: $renderInstructionNodes, values: $values}';
  }
}

/////////////////////////////////////////////////////////////////////////////

enum XmlElementType {
  RENDER_THEME,
  RENDERING_INSTRUCTION,
  RULE,
  RENDERING_STYLE,
}
