import 'package:mapsforge_flutter/src/rendertheme/rule/rendertheme.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlrendertheme.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlrenderthemestylemenu.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlrenderthmestylelayer.dart';
import 'package:xml/xml.dart';

import '../../graphics/graphicfactory.dart';
import '../../model/displaymodel.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../../rendertheme/rule/rule.dart';

/**
 * KXML handler to parse XML render theme files.
 */
class RenderThemeHandler {
  static final String ELEMENT_NAME_RULE = "rule";
  static final String UNEXPECTED_ELEMENT = "unexpected element: ";

  Set<String>? categories;
  Rule? currentRule;
  final DisplayModel displayModel;
  final List<Element> elementStack = [];
  final GraphicFactory graphicFactory;
  int level = 0;
  String? qName;
  final String relativePathPrefix;
  RenderTheme? renderTheme;
  final List<Rule> ruleStack = [];
  Map<String, Symbol> symbols = new Map<String, Symbol>();
  final XmlRenderTheme xmlRenderTheme;
  late XmlRenderThemeStyleMenu renderThemeStyleMenu;
  late XmlRenderThemeStyleLayer currentLayer;

  RenderThemeHandler(this.graphicFactory, this.displayModel, this.relativePathPrefix, this.xmlRenderTheme);

//  void processRenderTheme(Xml) {
//    int eventType = pullParser.getEventType();
//    do {
//      if (eventType == XmlPullParser.START_DOCUMENT) {
//// no-op
//      } else if (eventType == XmlPullParser.START_TAG) {
//        startElement();
//      } else if (eventType == XmlPullParser.END_TAG) {
//        endElement();
//      } else if (eventType == XmlPullParser.TEXT) {
//// not implemented
//      }
//      eventType = pullParser.next();
//    } while (eventType != XmlPullParser.END_DOCUMENT);
//    endDocument();
//  }

  void endDocument() {
    if (this.renderTheme == null) {
      throw new Exception("missing element: rules");
    }

    this.renderTheme!.setLevels(this.level);
    this.renderTheme!.complete();
  }

//  void endElement() {
//    qName = pullParser.getName();
//
//    this.elementStack.pop();
//
//    if (ELEMENT_NAME_RULE == qName) {
//      this.ruleStack.pop();
//      if (this.ruleStack.empty()) {
//        if (isVisible(this.currentRule)) {
//          this.renderTheme.addRule(this.currentRule);
//        }
//      } else {
//        this.currentRule = this.ruleStack.peek();
//      }
//    } else if ("stylemenu" == qName)
//    ) {
//// when we are finished parsing the menu part of the file, we can get the
//// categories to render from the initiator. This allows the creating action
//// to select which of the menu options to choose
//    if (null != this.xmlRenderTheme.getMenuCallback()) {
//// if there is no callback, there is no menu, so the categories will be null
//    this.categories = this.xmlRenderTheme.getMenuCallback().getCategories(
//    this.renderThemeStyleMenu);
//    }
//    return;
//    }
//  }

  void startElement(XmlNode node) {
    qName = node.text;

    if ("rendertheme" == qName) {
      checkState(qName, Element.RENDER_THEME);
//      this.renderTheme = new RenderThemeBuilder(
//          this.graphicFactory, this.displayModel, qName).build();
    } else if (ELEMENT_NAME_RULE == qName) {
      checkState(qName, Element.RULE);
//      Rule rule = new RuleBuilder(qName, pullParser, this.ruleStack).build();
//      if (!this.ruleStack.empty() && isVisible(rule)) {
//        this.currentRule.addSubRule(rule);
//      }
//      this.currentRule = rule;
//      this.ruleStack.push(this.currentRule);
    } else if ("area" == qName) {
//      checkState(qName, Element.RENDERING_INSTRUCTION);
//      Area area = new Area(
//          this.graphicFactory, this.displayModel, qName, pullParser,
//          this.level++,
//          this.relativePathPrefix);
//      if (isVisible(area)) {
//        this.currentRule.addRenderingInstruction(area);
//      }
    } else if ("caption" == qName) {
//      checkState(qName, Element.RENDERING_INSTRUCTION);
//      Caption caption = new Caption(
//          this.graphicFactory, this.displayModel, qName, pullParser, symbols);
//      if (isVisible(caption)) {
//        this.currentRule.addRenderingInstruction(caption);
//      }
    } else if ("cat" == qName) {
      checkState(qName, Element.RENDERING_STYLE);
      this.currentLayer.addCategory(getStringAttribute("id"));
    } else if ("circle" == qName) {
//      checkState(qName, Element.RENDERING_INSTRUCTION);
//      Circle circle = new Circle(
//          this.graphicFactory, this.displayModel, qName, pullParser,
//          this.level++);
//      if (isVisible(circle)) {
//        this.currentRule.addRenderingInstruction(circle);
//      }
    }

// rendertheme menu layer
    else if ("layer" == qName) {
      checkState(qName, Element.RENDERING_STYLE);
      bool enabled = false;
      if (getStringAttribute("enabled") != null) {
        enabled = getStringAttribute("enabled") == "true";
      }
      bool visible = getStringAttribute("visible") == "true";
      this.currentLayer = this.renderThemeStyleMenu.createLayer(getStringAttribute("id"), visible, enabled);
      String parent = getStringAttribute("parent");
      if (null != parent) {
        XmlRenderThemeStyleLayer? parentEntry = this.renderThemeStyleMenu.getLayer(parent);
        if (null != parentEntry) {
          for (String cat in parentEntry.getCategories()) {
            this.currentLayer.addCategory(cat);
          }
          for (XmlRenderThemeStyleLayer overlay in parentEntry.getOverlays()) {
            this.currentLayer.addOverlay(overlay);
          }
        }
      }
    } else if ("line" == qName) {
//    checkState(qName, Element.RENDERING_INSTRUCTION);
//    Line line = new Line(this.graphicFactory, this.displayModel, qName, pullParser, this.level++,
//    this.relativePathPrefix);
//    if (isVisible(line)) {
//    this.currentRule.addRenderingInstruction(line);
//    }
    } else if ("lineSymbol" == qName) {
//    checkState(qName, Element.RENDERING_INSTRUCTION);
//    LineSymbol lineSymbol = new LineSymbol(this.graphicFactory, this.displayModel, qName,
//    pullParser, this.relativePathPrefix);
//    if (isVisible(lineSymbol)) {
//    this.currentRule.addRenderingInstruction(lineSymbol);
//    }
    }

// render theme menu name
    else if ("name" == qName) {
      checkState(qName, Element.RENDERING_STYLE);
      this.currentLayer.addTranslation(getStringAttribute("lang"), getStringAttribute("value"));
    }

// render theme menu overlay
    else if ("overlay" == qName) {
      checkState(qName, Element.RENDERING_STYLE);
      XmlRenderThemeStyleLayer? overlay = this.renderThemeStyleMenu.getLayer(getStringAttribute("id"));
      if (overlay != null) {
        this.currentLayer.addOverlay(overlay);
      }
    } else if ("pathText" == qName) {
//      checkState(qName, Element.RENDERING_INSTRUCTION);
//      PathText pathText = new PathText(
//          this.graphicFactory, this.displayModel, qName, pullParser);
//      if (isVisible(pathText)) {
//        this.currentRule.addRenderingInstruction(pathText);
//      }
    } else if ("stylemenu" == qName) {
      checkState(qName, Element.RENDERING_STYLE);

      this.renderThemeStyleMenu =
          new XmlRenderThemeStyleMenu(getStringAttribute("id"), getStringAttribute("defaultlang"), getStringAttribute("defaultvalue"));
    } else if ("symbol" == qName) {
//      checkState(qName, Element.RENDERING_INSTRUCTION);
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
      checkState(qName, Element.RULE);
      String? category = null;
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

      int hillShadingLevel = this.level++;
//    Hillshading hillshading = new Hillshading(minZoom, maxZoom, magnitude, layer, always, hillShadingLevel, this.graphicFactory);

      if (this.categories == null || category == null || this.categories!.contains(category)) {
        //      this.renderTheme.addHillShadings(hillshading);
      }
    } else {
      throw new Exception("unknown element: " + qName!);
    }
  }

  void checkElement(String? elementName, Element element) {
    switch (element) {
      case Element.RENDER_THEME:
        if (!this.elementStack.isEmpty) {
          throw new Exception(UNEXPECTED_ELEMENT + elementName!);
        }
        return;

      case Element.RULE:
//        Element parentElement = this.elementStack.peek();
//        if (parentElement != Element.RENDER_THEME &&
//            parentElement != Element.RULE) {
//          throw new Exception(UNEXPECTED_ELEMENT + elementName);
//        }
        return;

      case Element.RENDERING_INSTRUCTION:
//        if (this.elementStack.peek() != Element.RULE) {
//          throw new Exception(UNEXPECTED_ELEMENT + elementName);
//        }
        return;

      case Element.RENDERING_STYLE:
        return;
    }

    throw new Exception("unknown enum value: " + element.toString());
  }

  void checkState(String? elementName, Element element) {
    checkElement(elementName, element);
//    this.elementStack.push(element);
  }

  String getStringAttribute(String name) {
//    int n = pullParser.getAttributeCount();
//    for (int i = 0; i < n; i++) {
//      if (pullParser.getAttributeName(i) == name)
//    ) {
//    return pullParser.getAttributeValue(i);
//    }
    return "unknownStringAttribute";
  }
//    return
//    null;
}

bool isVisible(RenderInstruction renderInstruction) {
//    return this.categories == null || renderInstruction.getCategory() == null ||
//        this.categories.contains(renderInstruction.getCategory());
//}

//  bool isVisible(Rule rule) {
//// a rule is visible if categories is not set, the rule has not category or the
//// categories contain this rule's category
//    return this.categories == null || rule.cat == null ||
//        this.categories.contains(rule.cat);
//  }
  return true;
}

/////////////////////////////////////////////////////////////////////////////

enum Element {
  RENDER_THEME,
  RENDERING_INSTRUCTION,
  RULE,
  RENDERING_STYLE,
}
