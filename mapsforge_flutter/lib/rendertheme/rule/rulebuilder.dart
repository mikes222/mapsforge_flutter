import '../../rendertheme/rule/rule.dart';

import '../xmlutils.dart';
import 'anymatcher.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'closedmatcher.dart';
import 'closedwaymatcher.dart';
import 'element.dart';
import 'elementmatcher.dart';
import 'elementnodematcher.dart';
import 'elementwaymatcher.dart';
import 'keymatcher.dart';
import 'linearwaymatcher.dart';
import 'negativematcher.dart';
import 'negativerule.dart';
import 'positiverule.dart';
import 'ruleoptimizer.dart';
import 'valuematcher.dart';

class RuleBuilder {
  static final String CAT = "cat";
  static final String CLOSED = "closed";
  static final String E = "e";
  static final String K = "k";
  static final Pattern SPLIT_PATTERN = Pattern.compile("\\|");
  static final String STRING_NEGATION = "~";
  static final String STRING_WILDCARD = "*";
  static final String V = "v";
  static final String ZOOM_MAX = "zoom-max";
  static final String ZOOM_MIN = "zoom-min";

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

    AttributeMatcher attributeMatcher = Rule.MATCHERS_CACHE_KEY.get(keyList);
    if (attributeMatcher == null) {
      attributeMatcher = new KeyMatcher(keyList);
      Rule.MATCHERS_CACHE_KEY.put(keyList, attributeMatcher);
    }
    return attributeMatcher;
  }

  static AttributeMatcher getValueMatcher(List<String> valueList) {
    if (STRING_WILDCARD == (valueList.elementAt(0))) {
      return AnyMatcher.INSTANCE;
    }

    AttributeMatcher attributeMatcher =
        Rule.MATCHERS_CACHE_VALUE.get(valueList);
    if (attributeMatcher == null) {
      attributeMatcher = new ValueMatcher(valueList);
      Rule.MATCHERS_CACHE_VALUE.put(valueList, attributeMatcher);
    }
    return attributeMatcher;
  }

  String cat;
  ClosedMatcher closedMatcher;
  ElementMatcher elementMatcher;
  int zoomMax;
  int zoomMin;
  Closed closed;
  Element element;
  List<String> keyList;
  String keys;
  final Stack<Rule> ruleStack;
  List<String> valueList;
  String values;

  RuleBuilder(
      String elementName, XmlPullParser pullParser, Stack<Rule> ruleStack) {
    this.ruleStack = ruleStack;

    this.closed = Closed.ANY;
    this.zoomMin = 0;
    this.zoomMax = 65536;

    extractValues(elementName, pullParser);
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

    keyMatcher = RuleOptimizer.optimize(keyMatcher, this.ruleStack);
    valueMatcher = RuleOptimizer.optimize(valueMatcher, this.ruleStack);

    return new PositiveRule(this, keyMatcher, valueMatcher);
  }

  void extractValues(String elementName, XmlPullParser pullParser) {
    for (int i = 0; i < pullParser.getAttributeCount(); ++i) {
      String name = pullParser.getAttributeName(i);
      String value = pullParser.getAttributeValue(i);

      if (E.equals(name)) {
        this.element = Element.fromString(value);
      } else if (K.equals(name)) {
        this.keys = value;
      } else if (V.equals(name)) {
        this.values = value;
      } else if (CAT.equals(name)) {
        this.cat = value;
      } else if (CLOSED.equals(name)) {
        this.closed = Closed.fromString(value);
      } else if (ZOOM_MIN.equals(name)) {
        this.zoomMin = XmlUtils.parseNonNegativeByte(name, value);
      } else if (ZOOM_MAX.equals(name)) {
        this.zoomMax = XmlUtils.parseNonNegativeByte(name, value);
      } else {
        throw XmlUtils.createXmlPullParserException(
            elementName, name, value, i);
      }
    }

    validate(elementName);

    this.keyList =
        new List<String>(Arrays.asList(SPLIT_PATTERN.split(this.keys)));

    this.valueList =
        new List<String>(Arrays.asList(SPLIT_PATTERN.split(this.values)));

    this.elementMatcher = getElementMatcher(this.element);

    this.closedMatcher = getClosedMatcher(this.closed);

    this.elementMatcher =
        RuleOptimizer.optimize(this.elementMatcher, this.ruleStack);

    this.closedMatcher =
        RuleOptimizer.optimize(this.closedMatcher, this.ruleStack);
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
}
