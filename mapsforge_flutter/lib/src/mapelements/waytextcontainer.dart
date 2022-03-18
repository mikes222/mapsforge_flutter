import 'package:flutter/widgets.dart';

import '../graphics/display.dart';
import '../graphics/filter.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/graphicutils.dart';
import '../graphics/mapcanvas.dart';
import '../graphics/mappaint.dart';
import '../graphics/mappath.dart';
import '../graphics/matrix.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../model/mappoint.dart';
import 'mapelementcontainer.dart';

class WayTextContainer extends MapElementContainer {
  final LineString lineString;
  final MapPaint paintFront;
  final MapPaint paintBack;
  final String text;
  final double textHeight;

  WayTextContainer(this.lineString, Display display,
      int priority, this.text, this.paintFront, this.paintBack, this.textHeight)
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
      int color = this.paintBack.getColor();
      if (filter != Filter.NONE) {
        this
            .paintBack
            .setColorFromNumber(GraphicUtils.filterColor(color, filter));
      }
      canvas.drawPathText(this.text, this.lineString, origin, this.paintBack);
      if (filter != Filter.NONE) {
        this.paintBack.setColorFromNumber(color);
      }
    }
    int color = this.paintFront.getColor();
    if (filter != Filter.NONE) {
      this
          .paintFront
          .setColorFromNumber(GraphicUtils.filterColor(color, filter));
    }
    canvas.drawPathText(this.text, this.lineString, origin, this.paintFront);
    if (filter != Filter.NONE) {
      this.paintFront.setColorFromNumber(color);
    }
  }

  @override
  String toString() {
    return 'WayTextContainer{lineString: $lineString, paintFront: $paintFront, paintBack: $paintBack, text: $text}';
  }
}
