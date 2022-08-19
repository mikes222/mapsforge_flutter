import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/paragraph_cache.dart';

import '../../graphics/display.dart';
import '../../graphics/mapcanvas.dart';
import '../../graphics/mappaint.dart';
import '../../model/linestring.dart';
import '../../model/mappoint.dart';
import 'mapelementcontainer.dart';

class WayTextContainer extends MapElementContainer {
  final LineString lineString;
  final MapPaint paintFront;
  final MapPaint paintBack;
  final MapTextPaint mapTextPaint;
  final String text;

  /// the maximum width of a text according to [DisplayModel]
  final double maxTextWidth;

  WayTextContainer(this.lineString, Display display, int priority, this.text,
      this.paintFront, this.paintBack, this.mapTextPaint, this.maxTextWidth)
      : super(lineString.segments.elementAt(0).start, display, priority) {
    ParagraphEntry entry =
        ParagraphCache().getEntry(text, mapTextPaint, paintFront, maxTextWidth);

    double textHeight = entry.getHeight();

    // a way text container should always run left to right, but I leave this in because it might matter
    // if we support right-to-left text.
    // we also need to make the container larger by textHeight as otherwise the end points do
    // not correctly reflect the size of the text on screen
    this.boundaryAbsolute = lineString.getBounds().enlarge(
        textHeight / 2, textHeight / 2, textHeight / 2, textHeight / 2);
  }

  @override
  void dispose() {}

  @override
  void draw(MapCanvas canvas, Mappoint origin) {
    canvas.drawPathText(this.text, this.lineString, origin, this.paintBack,
        mapTextPaint, maxTextWidth);
    canvas.drawPathText(this.text, this.lineString, origin, this.paintFront,
        mapTextPaint, maxTextWidth);
  }

  @override
  String toString() {
    return 'WayTextContainer{lineString: $lineString, paintFront: $paintFront, paintBack: $paintBack, text: $text}';
  }
}
