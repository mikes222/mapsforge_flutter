import '../graphics/display.dart';
import '../graphics/mappaint.dart';
import '../graphics/position.dart';
import '../mapelements/symbolcontainer.dart';
import '../model/mappoint.dart';
import 'mapelementcontainer.dart';

abstract class PointTextContainer extends MapElementContainer {
  bool? isVisible;
  final int maxTextWidth;
  final MapPaint paintBack;
  final MapPaint paintFront;
  final Position? position;
  final SymbolContainer? symbolContainer;
  final String text;
  int? textHeight;
  int? textWidth;

  /**
   * Create a new point container, that holds the x-y coordinates of a point, a text variable, two paint objects, and
   * a reference on a symbolContainer, if the text is connected with a POI.
   */
  PointTextContainer(Mappoint point, Display? display, int priority, this.text, this.paintFront, this.paintBack, this.symbolContainer,
      this.position, this.maxTextWidth)
      : super(point, display, priority) {
    if (paintBack != null) {
      this.textWidth = paintBack.getTextWidth(text);
      this.textHeight = paintBack.getTextHeight(text);
    } else {
      this.textWidth = paintFront.getTextWidth(text);
      this.textHeight = paintFront.getTextHeight(text);
    }
    this.isVisible = !this.paintFront.isTransparent() || (this.paintBack != null && !this.paintBack.isTransparent());
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
    if (this.text == (ptc.text) && this.xy!.distance(ptc.xy!) < 200) {
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
          isVisible == other.isVisible &&
          maxTextWidth == other.maxTextWidth &&
          paintBack == other.paintBack &&
          paintFront == other.paintFront &&
          position == other.position &&
          symbolContainer == other.symbolContainer &&
          text == other.text &&
          textHeight == other.textHeight &&
          textWidth == other.textWidth;

  @override
  int get hashCode =>
      super.hashCode ^
      isVisible.hashCode ^
      maxTextWidth.hashCode ^
      paintBack.hashCode ^
      paintFront.hashCode ^
      position.hashCode ^
      symbolContainer.hashCode ^
      text.hashCode ^
      textHeight.hashCode ^
      textWidth.hashCode;

  @override
  String toString() {
    return 'PointTextContainer{isVisible: $isVisible, maxTextWidth: $maxTextWidth, paintBack: $paintBack, paintFront: $paintFront, position: $position, symbolContainer: $symbolContainer, text: $text, textHeight: $textHeight, textWidth: $textWidth, ${super.toString()}';
  }
}
