import '../graphics/canvas.dart';
import '../graphics/display.dart';
import '../graphics/filter.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/graphicutils.dart';
import '../graphics/matrix.dart';
import '../graphics/paint.dart';
import '../graphics/path.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../model/mappoint.dart';

import 'mapelementcontainer.dart';

class WayTextContainer extends MapElementContainer {
  final GraphicFactory graphicFactory;
  final LineString lineString;
  final Paint paintFront;
  final Paint paintBack;
  final String text;

  WayTextContainer(
      this.graphicFactory,
      this.lineString,
      Display display,
      int priority,
      this.text,
      this.paintFront,
      this.paintBack,
      double textHeight)
      : super(lineString.segments.elementAt(0).start, display, priority) {
    this.boundary = null;
    // a way text container should always run left to right, but I leave this in because it might matter
    // if we support right-to-left text.
    // we also need to make the container larger by textHeight as otherwise the end points do
    // not correctly reflect the size of the text on screen
    this.boundaryAbsolute = lineString.getBounds().enlarge(
        textHeight / 2, textHeight / 2, textHeight / 2, textHeight / 2);
  }

  @override
  void draw(Canvas canvas, Mappoint origin, Matrix matrix, Filter filter) {
    Path path = generatePath(origin);

    if (this.paintBack != null) {
      int color = this.paintBack.getColor();
      if (filter != Filter.NONE) {
        this
            .paintBack
            .setColorFromNumber(GraphicUtils.filterColor(color, filter));
      }
      canvas.drawPathText(this.text, path, this.paintBack);
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
    canvas.drawPathText(this.text, path, this.paintFront);
    if (filter != Filter.NONE) {
      this.paintFront.setColorFromNumber(color);
    }
  }

  Path generatePath(Mappoint origin) {
    LineSegment firstSegment = this.lineString.segments.elementAt(0);
    // So text isn't upside down
    bool doInvert = firstSegment.end.x <= firstSegment.start.x;
    Path path = this.graphicFactory.createPath();

    if (!doInvert) {
      Mappoint start = firstSegment.start.offset(-origin.x, -origin.y);
      path.moveTo(start.x, start.y);
      for (int i = 0; i < this.lineString.segments.length; i++) {
        LineSegment segment = this.lineString.segments.elementAt(i);
        Mappoint end = segment.end.offset(-origin.x, -origin.y);
        path.lineTo(end.x, end.y);
      }
    } else {
      Mappoint end = this
          .lineString
          .segments
          .elementAt(this.lineString.segments.length - 1)
          .end
          .offset(-origin.x, -origin.y);
      path.moveTo(end.x, end.y);
      for (int i = this.lineString.segments.length - 1; i >= 0; i--) {
        LineSegment segment = this.lineString.segments.elementAt(i);
        Mappoint start = segment.start.offset(-origin.x, -origin.y);
        path.lineTo(start.x, start.y);
      }
    }
    return path;
  }

  @override
  String toString() {
    return 'WayTextContainer{graphicFactory: $graphicFactory, lineString: $lineString, paintFront: $paintFront, paintBack: $paintBack, text: $text}';
  }
}
