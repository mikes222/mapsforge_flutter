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
  final GraphicFactory graphicFactory;
  final LineString lineString;
  final MapPaint paintFront;
  final MapPaint paintBack;
  final String text;
  final double textHeight;

  WayTextContainer(
      this.graphicFactory, this.lineString, Display display, int priority, this.text, this.paintFront, this.paintBack, this.textHeight)
      : super(lineString.segments.elementAt(0).start, display, priority) {
    this.boundary = null;
    // a way text container should always run left to right, but I leave this in because it might matter
    // if we support right-to-left text.
    // we also need to make the container larger by textHeight as otherwise the end points do
    // not correctly reflect the size of the text on screen
    this.boundaryAbsolute = lineString.getBounds()!.enlarge(textHeight / 2, textHeight / 2, textHeight / 2, textHeight / 2);
  }

  @override
  void draw(MapCanvas canvas, Mappoint origin, Matrix matrix, Filter filter) {
    //MapPath path = _generatePath(origin);

    if (this.paintBack != null) {
      int color = this.paintBack.getColor();
      if (filter != Filter.NONE) {
        this.paintBack.setColorFromNumber(GraphicUtils.filterColor(color, filter));
      }
      canvas.drawPathText(this.text, this.lineString, origin, this.paintBack);
      if (filter != Filter.NONE) {
        this.paintBack.setColorFromNumber(color);
      }
    }
    int color = this.paintFront.getColor();
    if (filter != Filter.NONE) {
      this.paintFront.setColorFromNumber(GraphicUtils.filterColor(color, filter));
    }
    canvas.drawPathText(this.text, this.lineString, origin, this.paintFront);
    if (filter != Filter.NONE) {
      this.paintFront.setColorFromNumber(color);
    }
  }

  MapPath _generatePath(Mappoint origin) {
    LineSegment firstSegment = this.lineString.segments.elementAt(0);
    // So text isn't upside down
    bool doInvert = firstSegment.end.x <= firstSegment.start.x;
    MapPath path = this.graphicFactory.createPath();

    if (!doInvert) {
      Mappoint start = firstSegment.start.offset(-origin.x, -origin.y);
      path.moveTo(start.x, start.y);
      for (int i = 0; i < this.lineString.segments.length; i++) {
        LineSegment segment = this.lineString.segments.elementAt(i);
        Mappoint end = segment.end.offset(-origin.x, -origin.y);
        path.lineTo(end.x, end.y);
      }
    } else {
      Mappoint end = this.lineString.segments.elementAt(this.lineString.segments.length - 1).end.offset(-origin.x, -origin.y);
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
