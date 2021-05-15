import '../datastore/pointofinterest.dart';
import '../graphics/bitmap.dart';
import '../graphics/position.dart';

import '../graphics/mappaint.dart';
import '../rendertheme/rendercontext.dart';
import '../renderer/polylinecontainer.dart';
import '../graphics/display.dart';

/**
 * Callback methods for rendering areas, ways and points of interest (POIs).
 */
abstract class RenderCallback {
/**
 * Renders an area with the given parameters.
 *
 * @param renderContext
 * @param fill          the paint to be used for rendering the area.
 * @param stroke        an optional paint for the area casing (may be null).
 * @param level
 */
  void renderArea(final RenderContext renderContext, MapPaint? fill, MapPaint stroke, int level, PolylineContainer way);

/**
 * Renders an area caption with the given text.
 *
 * @param renderContext
 * @param display          display mode
 * @param priority         priority level
 * @param caption          the text.
 * @param horizontalOffset the horizontal offset of the text.
 * @param verticalOffset   the vertical offset of the text.
 * @param fill             the paint for the text.
 * @param stroke           the casing of the text (may be null).
 * @param position         optional position (may be null)
 * @param maxTextWidth     maximum text width .
 * @param way              the way for the caption.
 */
  void renderAreaCaption(final RenderContext renderContext, Display display, int priority, String caption, double horizontalOffset,
      double verticalOffset, MapPaint fill, MapPaint stroke, Position? position, int maxTextWidth, PolylineContainer way);

/**
 * Renders an area symbol with the given bitmap.
 *
 * @param renderContext
 * @param symbol
 */
  void renderAreaSymbol(
      final RenderContext renderContext, Display display, int priority, Bitmap? symbol, PolylineContainer way, MapPaint? symbolPaint);

/**
 * Renders a point of interest caption with the given text.
 *
 * @param renderContext
 * @param caption          the text to be rendered.
 * @param horizontalOffset the horizontal offset of the caption.
 * @param verticalOffset   the vertical offset of the caption.
 * @param fill             the paint to be used for rendering the text.
 * @param stroke           an optional paint for the text casing (may be null).
 * @param position
 */
  void renderPointOfInterestCaption(
      final RenderContext renderContext,
      Display display,
      int priority,
      String caption,
      double horizontalOffset,
      double verticalOffset,
      MapPaint fill,
      MapPaint stroke,
      Position? position,
      int maxTextWidth,
      PointOfInterest poi);

/**
 * Renders a point of interest circle with the given parameters.
 *
 * @param renderContext
 * @param radius        the radius of the circle.
 * @param fill          the paint to be used for rendering the circle.
 * @param stroke        an optional paint for the circle casing (may be null).
 * @param level
 */
  void renderPointOfInterestCircle(
      final RenderContext renderContext, double radius, MapPaint? fill, MapPaint stroke, int level, PointOfInterest poi);

/**
 * Renders a point of interest symbol with the given bitmap.
 *
 * @param renderContext
 * @param symbol
 */
  void renderPointOfInterestSymbol(
      final RenderContext renderContext, Display display, int priority, Bitmap? symbol, PointOfInterest poi, MapPaint? symbolPaint);

/**
 * Renders a way with the given parameters.
 *
 * @param renderContext
 * @param stroke        the paint to be used for rendering the way.
 * @param dy            the offset of the way.
 * @param level
 */
  void renderWay(final RenderContext renderContext, MapPaint stroke, double dy, int level, PolylineContainer way);

/**
 * Renders a way with the given symbol along the way path.
 *
 * @param renderContext
 * @param symbol        the symbol to be rendered.
 * @param dy            the offset of the way.
 * @param alignCenter   true if the symbol should be centered, false otherwise.
 * @param repeat        true if the symbol should be repeated, false otherwise.
 * @param repeatGap     distance between repetitions.
 * @param repeatStart
 */
  void renderWaySymbol(final RenderContext renderContext, Display display, int priority, Bitmap? symbol, double dy, bool alignCenter,
      bool repeat, double? repeatGap, double? repeatStart, bool? rotate, PolylineContainer way, MapPaint? symbolPaint);

/**
 * Renders a way with the given text along the way path.
 *
 * @param renderContext
 * @param text          the text to be rendered.
 * @param dy            the offset of the way text.
 * @param fill          the paint to be used for rendering the text.
 * @param stroke
 */
  void renderWayText(final RenderContext renderContext, Display display, int priority, String text, double dy, MapPaint fill,
      MapPaint stroke, bool? repeat, double? repeatGap, double? repeatStart, bool? rotate, PolylineContainer way);
}
