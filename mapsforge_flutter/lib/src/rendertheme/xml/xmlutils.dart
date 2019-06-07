import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/inputstream.dart';

import '../../graphics/graphicfactory.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../../rendertheme/themecallback.dart';

class XmlUtils {
  static final _log = new Logger('XmlUtils');

  static final String PREFIX_ASSETS = "assets:";
  static final String PREFIX_FILE = "file:";
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  static final String UNSUPPORTED_COLOR_FORMAT = "unsupported color format: ";

  static void checkMandatoryAttribute(String elementName, String attributeName, Object attributeValue) {
    if (attributeValue == null) {
      throw new Exception("missing attribute '" + attributeName + "' for element: " + elementName);
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
  static int getColor(GraphicFactory graphicFactory, String colorString, ThemeCallback themeCallback, RenderInstruction origin) {
    if (colorString.isEmpty || !colorString.startsWith("#")) {
      throw new Exception(UNSUPPORTED_COLOR_FORMAT + colorString);
    } else if (colorString.length == 7) {
      return getColorAlpha(graphicFactory, colorString, 255, 1, themeCallback, origin);
    } else if (colorString.length == 9) {
      return getColorAlpha(graphicFactory, colorString, int.parse(colorString.substring(1, 3), radix: 16), 3, themeCallback, origin);
    } else {
      throw new Exception(UNSUPPORTED_COLOR_FORMAT + colorString);
    }
  }

  static int parseNonNegativeByte(String name, String value) {
    int parsedByte = int.parse(value);
    if (parsedByte < 0) {
      throw new Exception("Attribute '" + name + "' must not be negative: $value");
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
      throw new Exception("Attribute '" + name + "' must not be negative: $value");
    }
    return parsedInt;
  }

  static void checkForNegativeValue(String name, double value) {
    if (value < 0) {
      throw new Exception("Attribute '" + name + "' must not be negative: $value");
    }
  }

  /**
   * Create InputStream from assets, file or jar resource.
   * <p/>
   * If the resource has not a location prefix, then the search order is (file, assets, jar).
   */
  static InputStream createInputStream(GraphicFactory graphicFactory, String relativePathPrefix, String src) {
    InputStream inputStream;
    if (src.startsWith(PREFIX_ASSETS)) {
      src = src.substring(PREFIX_ASSETS.length);
      inputStream = inputStreamFromAssets(graphicFactory, relativePathPrefix, src);
    } else if (src.startsWith(PREFIX_FILE)) {
      src = src.substring(PREFIX_FILE.length);
      inputStream = inputStreamFromFile(relativePathPrefix, src);
    } else if (src.startsWith(PREFIX_JAR) || src.startsWith(PREFIX_JAR_V1)) {
      if (src.startsWith(PREFIX_JAR)) {
        src = src.substring(PREFIX_JAR.length);
      } else if (src.startsWith(PREFIX_JAR_V1)) {
        src = src.substring(PREFIX_JAR_V1.length);
      }
      src = "patterns/" + src;
//      inputStream = inputStreamFromJar(relativePathPrefix, src);
    } else {
      inputStream = inputStreamFromFile(relativePathPrefix, src);

      if (inputStream == null) {
        inputStream = inputStreamFromAssets(graphicFactory, relativePathPrefix, src);
      }

//      if (inputStream == null) {
//        inputStream = inputStreamFromJar(relativePathPrefix, src);
//      }
    }

// Fallback to internal resources
//    if (inputStream == null) {
//      inputStream = inputStreamFromJar("/assets/", src);
//      if (inputStream != null) {
//        LOGGER.info("internal resource: " + src);
//      }
//    }

    if (inputStream != null) {
      return inputStream;
    }

    _log.severe("invalid resource: " + src);
    throw new Exception("invalid resource: " + src);
  }

  /**
   * Create InputStream from (platform specific) assets resource.
   */
  static InputStream inputStreamFromAssets(GraphicFactory graphicFactory, String relativePathPrefix, String src) {
    InputStream inputStream = null;
    try {
      inputStream = graphicFactory.platformSpecificSources(relativePathPrefix, src);
    } catch (e) {}
    if (inputStream != null) {
      return inputStream;
    }
    return null;
  }

  /**
   * Create InputStream from file resource.
   */
  static InputStream inputStreamFromFile(String relativePathPrefix, String src) {
    File file = getFile(relativePathPrefix, src);
//    if (!file.exists()) {
//      if (src.length > 0 && src.charAt(0) == File.separatorChar) {
//        file = getFile(relativePathPrefix, src.substring(1));
//      }
//      if (!file.exists()) {
//        file = null;
//      }
//    } else if (!file.isFile() || !file.canRead()) {
//      file = null;
//    }
//    if (file != null) {
//      return new FileInputStream(file);
//    }
    return null;
  }

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

  static int getColorAlpha(GraphicFactory graphicFactory, String colorString, int alpha, int rgbStartIndex, ThemeCallback themeCallback,
      RenderInstruction origin) {
    int red = int.parse(colorString.substring(rgbStartIndex, rgbStartIndex + 2), radix: 16);
    int green = int.parse(colorString.substring(rgbStartIndex + 2, rgbStartIndex + 4), radix: 16);
    int blue = int.parse(colorString.substring(rgbStartIndex + 4, rgbStartIndex + 6), radix: 16);

    int color = graphicFactory.createColorSeparate(alpha, red, green, blue);
    if (themeCallback != null) {
      color = themeCallback.getColor(origin, color);
    }
    return color;
  }

  static File getFile(String parentPath, String pathName) {
//    if (pathName.charAt(0) == File.separatorChar) {
//      return new File(pathName);
//    }
//    return new File(parentPath, pathName);
  }
}
