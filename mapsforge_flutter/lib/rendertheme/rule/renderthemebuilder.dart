import '../../graphics/graphicfactory.dart';
import '../../model/displaymodel.dart';
import '../../rendertheme/rule/rendertheme.dart';

/**
 * A builder for {@link RenderTheme} instances.
 */
class RenderThemeBuilder {

  static final String BASE_STROKE_WIDTH = "base-stroke-width";
  static final String BASE_TEXT_SIZE = "base-text-size";
  static final String MAP_BACKGROUND = "map-background";
  static final String MAP_BACKGROUND_OUTSIDE = "map-background-outside";
  static final int RENDER_THEME_VERSION = 6;
  static final String VERSION = "version";
  static final String XMLNS = "xmlns";
  static final String XMLNS_XSI = "xmlns:xsi";
  static final String XSI_SCHEMALOCATION = "xsi:schemaLocation";

  double baseStrokeWidth;
  double baseTextSize;
  final DisplayModel displayModel;
  bool hasBackgroundOutside;
  int mapBackground;
  int mapBackgroundOutside;
  int version;

  RenderThemeBuilder(GraphicFactory graphicFactory, this.displayModel,
      String elementName, XmlPullParser pullParser)

  throws XmlPullParserException

  {

  this

      .

  baseStrokeWidth

  =

  1;

  this

      .

  baseTextSize

  =

  1;

  this

      .

  mapBackground

  =

  graphicFactory.createColor

  (

  Color.WHITE

  );

  extractValues(graphicFactory, elementName, pullParser);
}

/**
 * @return a new {@code RenderTheme} instance.
 */
RenderTheme build() {
  return new RenderTheme(this);
}

void extractValues
(

GraphicFactory graphicFactory, String
elementName,

XmlPullParser pullParser
)

throws XmlPullParserException
{
for
(

int i = 0;
i
<
pullParser.getAttributeCount();
++
i) {
String name = pullParser.getAttributeName(i);
String value = pullParser.getAttributeValue(i);

if (XMLNS.equals(name)) {
continue;
} else if (XMLNS_XSI.equals(name)) {
continue;
} else if (XSI_SCHEMALOCATION.equals(name)) {
continue;
} else if (VERSION.equals(name)) {
this.version = Integer.valueOf(XmlUtils.parseNonNegativeInteger(name, value));
} else if (MAP_BACKGROUND.equals(name)) {
this.mapBackground = XmlUtils.getColor(graphicFactory, value, displayModel.getThemeCallback(), null);
} else if (MAP_BACKGROUND_OUTSIDE.equals(name)) {
this.mapBackgroundOutside = XmlUtils.getColor(graphicFactory, value, displayModel.getThemeCallback(), null);
this.hasBackgroundOutside = true;
} else if (BASE_STROKE_WIDTH.equals(name)) {
this.baseStrokeWidth = XmlUtils.parseNonNegativeFloat(name, value);
} else if (BASE_TEXT_SIZE.equals(name)) {
this.baseTextSize = XmlUtils.parseNonNegativeFloat(name, value);
} else {
throw XmlUtils.createXmlPullParserException(elementName, name, value, i);
}
}

validate(elementName);}

void validate(String elementName) {
  XmlUtils.checkMandatoryAttribute(elementName, VERSION, this.version);

  if (this.version > RENDER_THEME_VERSION) {
    throw new Exception("unsupported render theme version: $version");
  }
}}
