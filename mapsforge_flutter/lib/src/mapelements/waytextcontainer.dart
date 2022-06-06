import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';

import '../graphics/display.dart';
import '../graphics/filter.dart';
import '../graphics/graphicutils.dart';
import '../graphics/mapcanvas.dart';
import '../graphics/mappaint.dart';
import '../graphics/matrix.dart';
import '../model/linestring.dart';
import '../model/mappoint.dart';
import 'mapelementcontainer.dart';

class WayTextContainer extends MapElementContainer {
  final LineString lineString;
  final MapPaint paintFront;
  final MapPaint paintBack;
  final MapTextPaint mapTextPaint;
  final String text;
  final double textHeight;

  WayTextContainer(this.lineString, Display display, int priority, this.text,
      this.paintFront, this.paintBack, this.textHeight, this.mapTextPaint)
      : super(lineString.segments.elementAt(0).start, display, priority) {
    this.boundary = null;
    // a way text container should always run left to right, but I leave this in because it might matter
    // if we support right-to-left text.
    // we also need to make the container larger by textHeight as otherwise the end points do
    // not correctly reflect the size of the text on screen
    this.boundaryAbsolute = lineString.getBounds().enlarge(
        textHeight / 2, textHeight / 2, textHeight / 2, textHeight / 2);
  }

  @mustCallSuper
  @override
  dispose() {}

  @override
  void draw(MapCanvas canvas, Mappoint origin, Matrix matrix, Filter filter) {
    //MapPath path = _generatePath(origin);

    {
      int color = this.paintBack.getColorAsNumber();
      if (filter != Filter.NONE) {
        this
            .paintBack
            .setColorFromNumber(GraphicUtils.filterColor(color, filter));
      }
      canvas.drawPathText(this.text, this.lineString, origin, this.paintBack, mapTextPaint);
      if (filter != Filter.NONE) {
        this.paintBack.setColorFromNumber(color);
      }
    }
    int color = this.paintFront.getColorAsNumber();
    if (filter != Filter.NONE) {
      this
          .paintFront
          .setColorFromNumber(GraphicUtils.filterColor(color, filter));
    }
    canvas.drawPathText(this.text, this.lineString, origin, this.paintFront, mapTextPaint);
    if (filter != Filter.NONE) {
      this.paintFront.setColorFromNumber(color);
    }
  }

  @override
  String toString() {
    return 'WayTextContainer{lineString: $lineString, paintFront: $paintFront, paintBack: $paintBack, text: $text}';
  }
}
