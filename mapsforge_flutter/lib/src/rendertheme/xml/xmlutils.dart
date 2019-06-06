import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as imag;
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';
import 'package:mapsforge_flutter/src/inputstream.dart';

import '../../graphics/graphicfactory.dart';
import '../../graphics/resourcebitmap.dart';
import '../../model/displaymodel.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../../rendertheme/themecallback.dart';
import 'package:resource/resource.dart' show Resource;

class XmlUtils {
  static final _log = new Logger('XmlUtils');

  static final String PREFIX_ASSETS = "assets:";
  static final String PREFIX_FILE = "file:";
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  static final String UNSUPPORTED_COLOR_FORMAT = "unsupported color format: ";

  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static int DEFAULT_SIZE = 20;

  static void checkMandatoryAttribute(String elementName, String attributeName, Object attributeValue) {
    if (attributeValue == null) {
      throw new Exception("missing attribute '" + attributeName + "' for element: " + elementName);
    }
  }

  static Future<ResourceBitmap> createBitmap(GraphicFactory graphicFactory, DisplayModel displayModel, String relativePathPrefix,
      String src, int width, int height, int percent) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }

    if (src.startsWith(PREFIX_JAR) || src.startsWith(PREFIX_JAR_V1)) {
      if (src.startsWith(PREFIX_JAR)) {
        src = src.substring(PREFIX_JAR.length);
      } else if (src.startsWith(PREFIX_JAR_V1)) {
        src = src.substring(PREFIX_JAR_V1.length);
      }
      src = "packages/mapsforge_flutter/assets/" + src;
    }

//    InputStream inputStream = createInputStream(graphicFactory, relativePathPrefix, src);
//      String absoluteName = getAbsoluteName(relativePathPrefix, src);
// we need to hash with the width/height included as the same symbol could be required
// in a different size and must be cached with a size-specific hash
    if (src.toLowerCase().endsWith(".svg")) {
      //var resource = new Resource(src);
      //Uint8List content = await resource.readAsBytes();
      ByteData content = await rootBundle.load(src);

      final DrawableRoot svgRoot = await svg.fromSvgBytes(content.buffer.asUint8List(), src);

// If you only want the final Picture output, just use
      final ui.Picture picture = svgRoot.toPicture(
          size:
              ui.Size(width != 0 ? width.toDouble() : DEFAULT_SIZE.toDouble(), height != 0 ? height.toDouble() : DEFAULT_SIZE.toDouble()));
      ui.Image image = await picture.toImage(width != 0 ? width : DEFAULT_SIZE, height != 0 ? height : DEFAULT_SIZE);
      //print("image: " + image.toString());
      FlutterResourceBitmap result = FlutterResourceBitmap(image);
      return result;

      //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

      //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
    } else if (src.toLowerCase().endsWith(".png")) {
      ByteData content = await rootBundle.load(src);
      if (width != 0 && height != 0) {
        imag.Image image = imag.decodeImage(content.buffer.asUint8List());
        image = imag.copyResize(image, width: width, height: height);

        var codec = await ui.instantiateImageCodec(image.getBytes());
        // add additional checking for number of frames etc here
        var frame = await codec.getNextFrame();
        ui.Image img = frame.image;

        FlutterResourceBitmap result = FlutterResourceBitmap(img);
        return result;
      } else {
        var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
        // add additional checking for number of frames etc here
        var frame = await codec.getNextFrame();
        ui.Image img = frame.image;

        FlutterResourceBitmap result = FlutterResourceBitmap(img);
        return result;
      }

      //Image img = Image.memory(content.buffer.asUint8List());
      //MemoryImage image = MemoryImage(content.buffer.asUint8List());

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
