import 'filter.dart';

/**
 * Utility class for graphics operations.
 */
class GraphicUtils {
  /**
   * Color filtering.
   *
   * @param color  color value in layout 0xAARRGGBB.
   * @param filter filter to apply on the color.
   * @return the filtered color.
   */
  static int filterColor(int color, Filter filter) {
    if (filter == Filter.NONE) {
      return color;
    }
    int a = color >> 24;
    int r = (color >> 16) & 0xFF;
    int g = (color >> 8) & 0xFF;
    int b = color & 0xFF;
    switch (filter) {
      case Filter.GRAYSCALE:
        r = g = b = (0.213 * r + 0.715 * g + 0.072 * b).round();
        break;
      case Filter.GRAYSCALE_INVERT:
        r = g = b = 255 - (0.213 * r + 0.715 * g + 0.072 * b).round();
        break;
      case Filter.INVERT:
        r = 255 - r;
        g = 255 - g;
        b = 255 - b;
        break;
      case Filter.NONE:
        break;
    }
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /**
   * @param color color value in layout 0xAARRGGBB.
   * @return the alpha value for the color.
   */
  static int getAlpha(int color) {
    return (color >> 24) & 0xff;
  }

  /**
   * Given the original image size, as well as width, height, percent parameters,
   * can compute the final image size.
   *
   * @param picWidth    original image width
   * @param picHeight   original image height
   * @param scaleFactor scale factor to screen DPI
   * @param width       requested width (0: no change)
   * @param height      requested height (0: no change)
   * @param percent     requested scale percent (100: no change)
   */
  static List<double> imageSize(double picWidth, double picHeight,
      double scaleFactor, int width, int height, int percent) {
    double bitmapWidth = picWidth * scaleFactor;
    double bitmapHeight = picHeight * scaleFactor;

    double aspectRatio = picWidth / picHeight;

    if (width != 0 && height != 0) {
// both width and height set, override any other setting
      bitmapWidth = width.toDouble();
      bitmapHeight = height.toDouble();
    } else if (width == 0 && height != 0) {
// only width set, calculate from aspect ratio
      bitmapWidth = height * aspectRatio;
      bitmapHeight = height.toDouble();
    } else if (width != 0 && height == 0) {
// only height set, calculate from aspect ratio
      bitmapHeight = width / aspectRatio;
      bitmapWidth = width.toDouble();
    }

    if (percent != 100) {
      bitmapWidth *= percent / 100;
      bitmapHeight *= percent / 100;
    }

    return []; //{bitmapWidth, bitmapHeight};
  }
}
