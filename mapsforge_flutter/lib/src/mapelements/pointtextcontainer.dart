import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';

import '../graphics/display.dart';
import '../graphics/mappaint.dart';
import '../graphics/position.dart';
import '../model/mappoint.dart';
import 'mapelementcontainer.dart';

abstract class PointTextContainer extends MapElementContainer {
  final int maxTextWidth;
  final MapPaint paintBack;
  final MapPaint paintFront;
  final MapTextPaint mapTextPaint;
  final Position position;
  final String text;
  late double textHeight;
  late double textWidth;

  /// Create a new point container, that holds the x-y coordinates of a point, a text variable, two paint objects, and
  /// a reference on a symbolContainer, if the text is connected with a POI.
  PointTextContainer(
      Mappoint point,
      Display display,
      int priority,
      this.text,
      this.paintFront,
      this.paintBack,
      this.position,
      this.maxTextWidth,
      this.mapTextPaint)
      : super(point, display, priority) {
    this.textWidth = mapTextPaint.getTextWidth(text);
    this.textHeight = mapTextPaint.getTextHeight(text);
  }

  @override
  bool clashesWith(MapElementContainer other) {
    if (super.clashesWith(other)) {
      return true;
    }
    if (!(other is PointTextContainer)) {
      return false;
    }
    PointTextContainer ptc = other;
    if (this.text == (ptc.text) && this.xy.distance(ptc.xy) < 200) {
      return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PointTextContainer &&
          runtimeType == other.runtimeType &&
          maxTextWidth == other.maxTextWidth &&
          paintBack == other.paintBack &&
          paintFront == other.paintFront &&
          position == other.position &&
          text == other.text &&
          textHeight == other.textHeight &&
          textWidth == other.textWidth;

  @override
  int get hashCode =>
      super.hashCode ^
      maxTextWidth.hashCode ^
      paintBack.hashCode ^
      paintFront.hashCode ^
      position.hashCode ^
      text.hashCode ^
      textHeight.hashCode ^
      textWidth.hashCode;

  @override
  String toString() {
    return 'PointTextContainer{maxTextWidth: $maxTextWidth, paintBack: $paintBack, paintFront: $paintFront, position: $position, text: $text, textHeight: $textHeight, textWidth: $textWidth, ${super.toString()}';
  }
}
