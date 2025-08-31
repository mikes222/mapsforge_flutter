class XmlUtils {
  static final String PREFIX_ASSETS = "assets:";
  static final String PREFIX_FILE = "file:";
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  static final String UNSUPPORTED_COLOR_FORMAT = "unsupported color format: ";

  static void checkMandatoryAttribute(String elementName, String attributeName, Object? attributeValue) {
    if (attributeValue == null) {
      throw Exception("missing attribute '$attributeName' for element: $elementName");
    }
  }

  /**
   * Supported formats are {@code #RRGGBB} and {@code #AARRGGBB}.
   */
  //  static int getColor(GraphicFactory graphicFactory, String colorString) {
  //    return getColor(graphicFactory, colorString, null, null);
  //  }

  /**
   * Supported formats are {@code #RRGGBB} and {@code #AARRGGBB}.
   */
  static int getColor(String colorString) {
    if (colorString.isEmpty || !colorString.startsWith("#")) {
      throw new Exception(UNSUPPORTED_COLOR_FORMAT + colorString);
    } else if (colorString.length == 7) {
      return getColorAlpha(colorString, 255, 1);
    } else if (colorString.length == 9) {
      return getColorAlpha(colorString, int.parse(colorString.substring(1, 3), radix: 16), 3);
    } else {
      throw new Exception(UNSUPPORTED_COLOR_FORMAT + colorString);
    }
  }

  static int parseNonNegativeByte(String name, String value) {
    int parsedByte = int.parse(value);
    if (parsedByte < 0) {
      throw new Exception("Attribute '$name' must not be negative: $value");
    }
    return parsedByte;
  }

  static double parseNonNegativeFloat(String name, String value) {
    double parsedFloat = double.parse(value);
    checkForNegativeValue(name, parsedFloat);
    return parsedFloat;
  }

  static int parseNonNegativeInteger(String name, String value) {
    int parsedInt = int.parse(value);
    if (parsedInt < 0) {
      throw new Exception("Attribute '$name' must not be negative: $value");
    }
    return parsedInt;
  }

  static void checkForNegativeValue(String name, double value) {
    if (value < 0) {
      throw new Exception("Attribute '$name' must not be negative: $value");
    }
  }

  /**
   * Create InputStream from (platform specific) assets resource.
   */
  // static InputStream inputStreamFromAssets(GraphicFactory graphicFactory, String relativePathPrefix, String src) {
  //   InputStream inputStream = null;
  //   try {
  //     inputStream = graphicFactory.platformSpecificSources(relativePathPrefix, src);
  //   } catch (e) {}
  //   if (inputStream != null) {
  //     return inputStream;
  //   }
  //   return null;
  // }

  /**
   * Create InputStream from jar resource.
   */
  //  static InputStream inputStreamFromJar(String relativePathPrefix, String src) {
  //    String absoluteName = getAbsoluteName(relativePathPrefix, src);
  //    return XmlUtils
  //    .
  //    class
  //    .
  //    getResourceAsStream
  //    (
  //    absoluteName
  //    );
  //  }

  static String getAbsoluteName(String relativePathPrefix, String name) {
    //    if (name.charAt(0) == File.separatorChar) {
    //      return name;
    //    }
    return relativePathPrefix + name;
  }

  static int getColorAlpha(String colorString, int alpha, int rgbStartIndex) {
    int red = int.parse(colorString.substring(rgbStartIndex, rgbStartIndex + 2), radix: 16);
    int green = int.parse(colorString.substring(rgbStartIndex + 2, rgbStartIndex + 4), radix: 16);
    int blue = int.parse(colorString.substring(rgbStartIndex + 4, rgbStartIndex + 6), radix: 16);

    int color = createColorSeparate(alpha, red, green, blue);
    return color;
  }

  static int createColorSeparate(int alpha, int red, int green, int blue) {
    return alpha << 24 | red << 16 | green << 8 | blue;
  }
}
