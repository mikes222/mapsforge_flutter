import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closed.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closedmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closedwaymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/element.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/elementmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/elementnodematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/elementwaymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/linearwaymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/negativematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_area.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_caption.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_circle.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_hillshading.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_linesymbol.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_polyline.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_polyline_text.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_symbol.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter_rendertheme/src/rule/negativerule.dart';
import 'package:mapsforge_flutter_rendertheme/src/rule/positiverule.dart';
import 'package:mapsforge_flutter_rendertheme/src/rule/ruleoptimizer.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

class RuleBuilder {
  static final _log = Logger('RuleBuilder');

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

  /// Do not import rules with the given id
  final Set<String> excludeIds;

  final RenderThemeBuilder renderThemeBuilder;

  /// The level of this rule. Starting with 0. Each level gets a unique id in ascending order from top to bottom of the rendertheme.
  /// This way we can draw for example the black line of all streets at once (in a lower level) and THEN draw the yellowish lines of all streets above it In a higher level).
  /// This leads to the illusion of joining the streets.
  int _level = -1;

  /// The category defined for this rule
  String? cat;

  /// The id of this rule
  String? id;

  /// The zoomlevel range which this rule applies to.
  ZoomlevelRange zoomlevelRange;

  /// A boolean variable which will be set to true if this rule can never be
  /// executed. This may happen for example if the [DisplayModel] sets the
  /// max zoom size to for example 9 and the rule has a min-zoom size of 10.
  bool impossible = false;

  Closed closed = Closed.ANY;
  Element element = Element.ANY;
  String? keys;
  final List<RenderinstructionNode> renderinstructionNodes;
  final List<RenderinstructionWay> renderinstructionOpenWays;
  final List<RenderinstructionWay> renderinstructionClosedWays;

  // rules directly below this rule
  final List<RuleBuilder> ruleBuilderStack;

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
    return RuleOptimizer.optimizeElementMatcher(result, ruleBuilderStack);
  }

  RuleBuilder(this.renderThemeBuilder, {Set<String>? excludeIds})
    : excludeIds = excludeIds ?? {},
      zoomlevelRange = const ZoomlevelRange.standard(),
      ruleBuilderStack = [],
      renderinstructionNodes = [],
      renderinstructionOpenWays = [],
      renderinstructionClosedWays = [] {
    closed = Closed.ANY;
    element = Element.ANY;
  }

  void validateTree() {
    for (RuleBuilder ruleBuilder in ruleBuilderStack) {
      if (element == Element.NODE && ruleBuilder.element == Element.WAY) {
        _log.warning("Impossible SubRule which has element way (${ruleBuilder.element}) whereas the parent has element node ($element)");
      }
      if (element == Element.WAY && ruleBuilder.element == Element.NODE) {
        _log.warning("Impossible SubRule which has element node ($ruleBuilder) whereas the parent has element way ($this)");
      }
      if (closed == Closed.YES && ruleBuilder.closed == Closed.NO) {
        _log.warning("Impossible SubRule which has closed no ($ruleBuilder) whereas the parent has closed yes ($this)");
      }
      if (closed == Closed.NO && ruleBuilder.closed == Closed.YES) {
        _log.warning("Impossible SubRule which has closed yes ($ruleBuilder) whereas the parent has closed no ($this)");
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
    if (element == Element.NODE && renderinstructionNodes.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionNodes whereas the parent has element node ($this)");
    }
    if (element == Element.WAY && renderinstructionOpenWays.isEmpty && renderinstructionClosedWays.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionWays whereas the parent has element way ($this)");
    }
    if (renderinstructionNodes.isEmpty && renderinstructionOpenWays.isEmpty && renderinstructionClosedWays.isEmpty && ruleBuilderStack.isEmpty) {
      _log.warning("Impossible SubRule which has no renderInstructionNodes or renderInstructionWays ($this)");
    }
  }

  /// @return a new {@code Rule} instance.
  Rule build() {
    List<Rule> rules = [];
    for (var ruleBuilder in ruleBuilderStack) {
      if (!ruleBuilder.impossible) {
        Rule rule = ruleBuilder.build();
        rules.add(rule);
      }
    }
    if (negativeMatcher != null) {
      return NegativeRule(
        attributeMatcher: negativeMatcher!,
        zoomlevelRange: zoomlevelRange,
        subRules: rules,
        renderinstructionNodes: renderinstructionNodes,
        renderinstructionOpenWays: renderinstructionOpenWays,
        renderinstructionClosedWays: renderinstructionClosedWays,
      );
    }

    if (renderinstructionNodes.isEmpty && renderinstructionOpenWays.isEmpty && renderinstructionClosedWays.isEmpty) {
      keyMatcher = RuleOptimizer.optimize(keyMatcher, ruleBuilderStack);
      valueMatcher = RuleOptimizer.optimize(valueMatcher, ruleBuilderStack);
    }

    return PositiveRule(
      keyMatcher: keyMatcher,
      valueMatcher: valueMatcher,
      zoomlevelRange: zoomlevelRange,
      subRules: rules,
      renderinstructionNodes: renderinstructionNodes,
      renderinstructionOpenWays: renderinstructionOpenWays,
      renderinstructionClosedWays: renderinstructionClosedWays,
    );
  }

  void parse(XmlNode rootElement) {
    for (var attribute in rootElement.attributes) {
      String name = attribute.name.toString();

      String value = attribute.value;
      //_log.info("checking $name=$value");
      if (E == name) {
        element = Element.values.firstWhere((ele) => ele.toString().toLowerCase().contains(value));
      } else if (K == name) {
        keys = value;
      } else if (V == name) {
        values = value;
      } else if (CAT == name) {
        cat = value;
      } else if (ID == name) {
        id = value;
      } else if (CLOSED == name) {
        closed = Closed.values.firstWhere((ele) => ele.toString().toLowerCase().contains(value));
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
    }

    validate(rootElement.toString());

    List<String> keyList = keys!.split(SPLIT_PATTERN);
    List<String> valueList = values!.split(SPLIT_PATTERN);

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
            _parseSubElement(element);
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
    XmlUtils.checkMandatoryAttribute(elementName, E, element);

    XmlUtils.checkMandatoryAttribute(elementName, K, keys);

    XmlUtils.checkMandatoryAttribute(elementName, V, values);

    if (zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) {
      // we cannot throw an exception. The xml file may contain a rule with zoomMin > e.g. 12 but we only allow e.g. zoomMax 9 in displayModel. The xml is NOT
      // invalid in that case
      // throw new Exception(
      //     "ZoomMin ${zoomlevelRange.zoomlevelMin} > ZoomMax ${zoomlevelRange.zoomlevelMax} for rule with $keys and $values and childs ${ruleBuilderStack.toString()}");
    }
  }

  void _parseSubElement(XmlElement rootElement) {
    String qName = rootElement.name.toString();

    if ("rule" == qName) {
      String? ruleId = rootElement.getAttribute("id");
      if (ruleId != null && excludeIds.contains(ruleId)) {
        _log.info("Excluding rule with id: $ruleId");
        return; // Skip parsing this rule entirely.
      }
      checkState(qName, XmlElementType.RULE);
      RuleBuilder ruleBuilder = RuleBuilder(renderThemeBuilder, excludeIds: excludeIds);
      ruleBuilder.zoomlevelRange = zoomlevelRange;

      try {
        ruleBuilder.parse(rootElement);
      } catch (error, stacktrace) {
        _log.warning("Error while parsing rule $ruleBuilder which is a subrule of $this", error, stacktrace);
        print("error: $error");
        print("stacktrace: $stacktrace");
      }
      ruleBuilderStack.add(ruleBuilder);
      // after parsing we get the current max levels from this subrule and use it for the next subrules.
    } else if ("area" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionArea area = RenderinstructionArea(getNextLevel());
      area.parse(rootElement);
      if (isVisibleWay(area)) {
        if (closed != Closed.NO) addRenderingInstructionClosedWay(area);
      }
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionSymbol symbol = RenderinstructionSymbol(getNextLevel());
      symbol.parse(rootElement);
      // Skip if the symbol's id is in the excluded set.
      if (symbol.id != null && excludeIds.contains(symbol.id)) {
        _log.info("Excluding symbol with id: ${symbol.id}");
      } else {
        if (isVisible(symbol)) {
          if (element != Element.WAY) addRenderingInstructionNode(symbol);
          if (closed != Closed.NO) addRenderingInstructionClosedWay(symbol);
        }
      }
    } else if ("caption" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionCaption caption = RenderinstructionCaption(getNextLevel());
      caption.parse(rootElement);
      if (isVisible(caption)) {
        if (element != Element.WAY) addRenderingInstructionNode(caption);
        if (closed != Closed.NO) addRenderingInstructionClosedWay(caption);
        //        maxLevel = max(maxLevel, level);
      }
    } else if ("cat" == qName) {
      checkState(qName, XmlElementType.RENDERING_STYLE);
      //this.currentLayer.addCategory(getStringAttribute("id"));
    } else if ("circle" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionCircle circle = RenderinstructionCircle(getNextLevel());
      circle.parse(rootElement);
      if (isVisible(circle)) {
        if (element != Element.WAY) addRenderingInstructionNode(circle);
      }
    } else if ("line" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionPolyline line = RenderinstructionPolyline(getNextLevel());

      line.parse(rootElement);
      if (line.id != null && excludeIds.contains(line.id)) {
        _log.info("Excluding symbol with id: ${line.id}");
      } else {
        if (isVisibleWay(line)) {
          if (closed != Closed.YES) addRenderingInstructionOpenWay(line);
          if (closed != Closed.NO) addRenderingInstructionClosedWay(line);
        }
      }
    } else if ("lineSymbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionLinesymbol lineSymbol = RenderinstructionLinesymbol(getNextLevel());
      lineSymbol.parse(rootElement);
      if (isVisibleWay(lineSymbol)) {
        if (closed != Closed.YES) addRenderingInstructionOpenWay(lineSymbol);
        if (closed != Closed.NO) addRenderingInstructionClosedWay(lineSymbol);
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
      RenderinstructionPolylineText pathText = RenderinstructionPolylineText(getNextLevel());
      pathText.parse(rootElement);
      if (isVisibleWay(pathText)) {
        if (closed != Closed.YES) addRenderingInstructionOpenWay(pathText);
        if (closed != Closed.NO) addRenderingInstructionClosedWay(pathText);
        //maxLevel = max(maxLevel, level);
      }
    } else if ("symbol" == qName) {
      checkState(qName, XmlElementType.RENDERING_INSTRUCTION);
      RenderinstructionSymbol symbol = RenderinstructionSymbol(getNextLevel());
      symbol.parse(rootElement);
      if (isVisible(symbol)) {
        if (element != Element.WAY) addRenderingInstructionNode(symbol);
        if (closed != Closed.NO) addRenderingInstructionClosedWay(symbol);
        //maxLevel = max(maxLevel, level);
      }
    } else if ("hillshading" == qName) {
      checkState(qName, XmlElementType.RULE);

      RenderinstructionHillshading hillshading = RenderinstructionHillshading(getNextLevel());
      hillshading.parse(rootElement);

      //      if (this.categories == null || category == null || this.categories.contains(category)) {
      hillShadings.add(hillshading);
      //      }
    } else {
      throw Exception("unknown element: $qName, $rootElement");
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

  bool isVisible(RenderinstructionNode renderInstructionNode) {
    return true;
    //return this.categories == null || renderInstruction.getCategory() == null || this.categories.contains(renderInstruction.getCategory());
  }

  bool isVisibleWay(RenderinstructionWay renderInstructionWay) {
    return true;
    //return this.categories == null || renderInstruction.getCategory() == null || this.categories.contains(renderInstruction.getCategory());
  }

  bool isVisibleRule(Rule rule) {
    // a rule is visible if categories is not set, the rule has not category or the
    // categories contain this rule's category
    return true;
    //return this.categories == null || rule.cat == null || this.categories.contains(rule.cat);
  }

  int getNextLevel() {
    if (_level == -1) {
      _level = renderThemeBuilder.getNextLevel();
    }
    return _level;
  }

  void addRenderingInstructionNode(RenderinstructionNode renderInstructionNode) {
    renderinstructionNodes.add(renderInstructionNode);
  }

  void addRenderingInstructionOpenWay(RenderinstructionWay renderInstructionWay) {
    renderinstructionOpenWays.add(renderInstructionWay);
  }

  void addRenderingInstructionClosedWay(RenderinstructionWay renderInstructionWay) {
    renderinstructionClosedWays.add(renderInstructionWay);
  }

  @override
  String toString() {
    return 'RuleBuilder{zoomlevelRange: $zoomlevelRange, element: $element, keys: $keys, renderInstructionNodes: $renderinstructionNodes, values: $values}';
  }
}

/////////////////////////////////////////////////////////////////////////////

enum XmlElementType { RENDER_THEME, RENDERING_INSTRUCTION, RULE, RENDERING_STYLE }
