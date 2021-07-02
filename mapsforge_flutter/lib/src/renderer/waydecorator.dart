import 'dart:math';

import '../graphics/bitmap.dart';
import '../graphics/display.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/mappaint.dart';
import '../mapelements/mapelementcontainer.dart';
import '../mapelements/symbolcontainer.dart';
import '../mapelements/waytextcontainer.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../model/mappoint.dart';
import '../model/tile.dart';
import '../renderer/rendererutils.dart';

class WayDecorator {
  static final double MAX_LABEL_CORNER_ANGLE = 45;

  static void renderSymbol(
      Bitmap symbolBitmap,
      Display display,
      int priority,
      double dy,
      bool alignCenter,
      bool repeatSymbol,
      int repeatGap,
      int repeatStart,
      bool? rotate,
      List<List<Mappoint>?>? coordinates,
      List<MapElementContainer> currentItems,
      MapPaint? symbolPaint) {
    int skipPixels = repeatStart;

    List<Mappoint?>? c;
    if (dy == 0) {
      c = coordinates![0];
    } else {
      c = RendererUtils.parallelPath(coordinates![0]!, dy);
    }

    // get the first way point coordinates
    double previousX = c![0]!.x;
    double previousY = c[0]!.y;

    // draw the symbolContainer on each way segment
    int segmentLengthRemaining;
    double segmentSkipPercentage;
    double theta = 0;

    for (int i = 1; i < c.length; ++i) {
      // get the current way point coordinates
      double currentX = c[i]!.x;
      double currentY = c[i]!.y;

      // calculate the length of the current segment (Euclidian distance)
      double diffX = currentX - previousX;
      double diffY = currentY - previousY;
      double segmentLengthInPixel = sqrt(diffX * diffX + diffY * diffY);
      segmentLengthRemaining = segmentLengthInPixel.round();

      while (segmentLengthRemaining - skipPixels > repeatStart) {
        // calculate the percentage of the current segment to skip
        segmentSkipPercentage = skipPixels / segmentLengthRemaining;

        // move the previous point forward towards the current point
        previousX += diffX * segmentSkipPercentage;
        previousY += diffY * segmentSkipPercentage;
        if (rotate!) {
          // if we do not rotate theta will be 0, which is correct
          theta = atan2(currentY - previousY, currentX - previousX);
        }

        Mappoint point = new Mappoint(previousX, previousY);

        currentItems
            .add(new SymbolContainer(point, display, priority, symbolBitmap, theta: theta, alignCenter: alignCenter, paint: symbolPaint!));

        // check if the symbolContainer should only be rendered once
        if (!repeatSymbol) {
          return;
        }

        // recalculate the distances
        diffX = currentX - previousX;
        diffY = currentY - previousY;

        // recalculate the remaining length of the current segment
        segmentLengthRemaining -= skipPixels;

        // set the amount of pixels to skip before repeating the symbolContainer
        skipPixels = repeatGap;
      }

      skipPixels -= segmentLengthRemaining;
      if (skipPixels < repeatStart) {
        skipPixels = repeatStart;
      }

      // set the previous way point coordinates for the next loop
      previousX = currentX;
      previousY = currentY;
    }
  }

  /**
   * Finds the segments of a line along which a name can be drawn and then adds WayTextContainers
   * to the list of drawable items.
   *
   * @param upperLeft     the tile in the upper left corner of the drawing pane
   * @param lowerRight    the tile in the lower right corner of the drawing pane
   * @param text          the text to draw
   * @param priority      priority of the text
   * @param dy            if 0, then a line  parallel to the coordinates will be calculated first
   * @param fill          fill paint for text
   * @param stroke        stroke paint for text
   * @param coordinates   the list of way coordinates
   * @param currentLabels the list of labels to which a new WayTextContainer will be added
   */
  static void renderText(
      GraphicFactory graphicFactory,
      Tile upperLeft,
      String text,
      Display display,
      int priority,
      double dy,
      MapPaint fill,
      MapPaint stroke,
      bool? repeat,
      double repeatGap,
      double repeatStart,
      bool? rotate,
      List<List<Mappoint>> coordinates,
      List<MapElementContainer> currentLabels) {
    if (coordinates.length == 0) {
      return;
    }

    List<Mappoint>? c;
    if (dy == 0) {
      c = coordinates[0];
    } else {
      c = RendererUtils.parallelPath(coordinates[0], dy);
    }

    if (c.length < 2) {
      return;
    }

    LineString path = new LineString();
    for (int i = 1; i < c.length; i++) {
      LineSegment segment = new LineSegment(c[i - 1], c[i]);
      path.segments.add(segment);
    }

    int textWidth = stroke.getTextWidth(text);
    int textHeight = stroke.getTextHeight(text);

    double pathLength = path.length();

    for (double pos = repeatStart; pos + textWidth < pathLength; pos += repeatGap + textWidth) {
      LineString linePart = path.extractPart(pos, pos + textWidth);

      bool tooSharp = false;
      for (int i = 1; i < linePart.segments.length; i++) {
        double cornerAngle = linePart.segments.elementAt(i - 1).angleTo(linePart.segments.elementAt(i));
        if ((cornerAngle).abs() > MAX_LABEL_CORNER_ANGLE) {
          tooSharp = true;
          break;
        }
      }
      if (tooSharp) continue;

      currentLabels.add(new WayTextContainer(graphicFactory, linePart, display, priority, text, fill, stroke, textHeight.toDouble()));
    }
  }
}
