import 'dart:ui' as ui;

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/paragraph_cache.dart';
import 'package:mapsforge_flutter/src/model/rectangle.dart';

import '../../graphics/display.dart';
import '../../graphics/mappaint.dart';
import '../../graphics/position.dart';
import '../../model/mappoint.dart';
import 'mapelementcontainer.dart';

class PointTextContainer extends MapElementContainer {
  final MapPaint paintBack;
  final MapPaint paintFront;
  final MapTextPaint mapTextPaint;
  final Position position;
  final String text;

  final double maxTextWidth;

  late ParagraphEntry front;

  late ParagraphEntry back;

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
    this.mapTextPaint,
    this.maxTextWidth,
  ) : super(point, display, priority) {
    // TextPaint frontTextPaint = new TextPaint(AndroidGraphicFactory.getPaint(this.paintFront));
    //TextPaint backTextPaint = null;
    //backTextPaint = new TextPaint(AndroidGraphicFactory.getPaint(this.paintBack));

    ui.TextAlign alignment = ui.TextAlign.center;
    if (Position.LEFT == this.position ||
        Position.BELOW_LEFT == this.position ||
        Position.ABOVE_LEFT == this.position) {
      //alignment = Layout.Alignment.ALIGN_OPPOSITE;
    } else if (Position.RIGHT == this.position ||
        Position.BELOW_RIGHT == this.position ||
        Position.ABOVE_RIGHT == this.position) {
      //alignment = Layout.Alignment.ALIGN_NORMAL;
    }

    // strange Android behaviour: if alignment is set to center, then
    // text is rendered with right alignment if using StaticLayout

//      frontLayout = new StaticLayout(
//          this.text,
//          frontTextPaint,
//          this.maxTextWidth,
//          alignment,
//          1,
//          0,
//          false);
//      backLayout = null;
//      if (this.paintBack != null) {
//        backLayout = new StaticLayout(
//            this.text,
//            backTextPaint,
//            this.maxTextWidth,
//            alignment,
//            1,
//            0,
//            false);
//      }

//      boxWidth = frontLayout.getWidth();
//      boxHeight = frontLayout.getHeight();

    front =
        ParagraphCache().getEntry(text, mapTextPaint, paintFront, maxTextWidth);
    back =
        ParagraphCache().getEntry(text, mapTextPaint, paintBack, maxTextWidth);

    double boxWidth = front.getWidth();
    double boxHeight = front.getHeight();

    switch (this.position) {
      case Position.CENTER:
        boundary = new Rectangle(
            -boxWidth / 2, -boxHeight / 2, boxWidth / 2, boxHeight / 2);
        break;
      case Position.BELOW:
        boundary = new Rectangle(-boxWidth / 2, 0, boxWidth / 2, boxHeight);
        break;
      case Position.BELOW_LEFT:
        boundary = new Rectangle(-boxWidth, 0, 0, boxHeight);
        break;
      case Position.BELOW_RIGHT:
        boundary = new Rectangle(0, 0, boxWidth, boxHeight);
        break;
      case Position.ABOVE:
        boundary = new Rectangle(-boxWidth / 2, -boxHeight, boxWidth / 2, 0);
        break;
      case Position.ABOVE_LEFT:
        boundary = new Rectangle(-boxWidth, -boxHeight, 0, 0);
        break;
      case Position.ABOVE_RIGHT:
        boundary = new Rectangle(0, -boxHeight, boxWidth, 0);
        break;
      case Position.LEFT:
        boundary = new Rectangle(-boxWidth, -boxHeight / 2, 0, boxHeight / 2);
        break;
      case Position.RIGHT:
        boundary = new Rectangle(0, -boxHeight / 2, boxWidth, boxHeight / 2);
        break;
      case Position.AUTO:
        boundary = new Rectangle(
            -boxWidth / 2, -boxHeight / 2, boxWidth / 2, boxHeight / 2);
        break;
    }
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
  Future<void> draw(MapCanvas canvas, Mappoint origin, Matrix matrix,
      Filter filter, SymbolCache symbolCache) async {
    ui.Canvas? flutterCanvas = (canvas as FlutterCanvas).uiCanvas;

    // the origin of the text is the base line, so we need to make adjustments
    // so that the text will be within its box
    double textOffset = 0;
    switch (this.position) {
      case Position.CENTER:
      case Position.LEFT:
      case Position.RIGHT:
        //textOffset = textHeight / 2;
        break;
      case Position.BELOW:
      case Position.BELOW_LEFT:
      case Position.BELOW_RIGHT:
        //textOffset = textHeight.toDouble();
        break;
      default:
        break;
    }

    double adjustedX = (this.xy.x - origin.x) + boundary!.left;
    double adjustedY = (this.xy.y - origin.y) + textOffset + boundary!.top;

    flutterCanvas.drawParagraph(
        back.paragraph, ui.Offset(adjustedX, adjustedY));
    flutterCanvas.drawParagraph(
        front.paragraph, ui.Offset(adjustedX, adjustedY));
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
          text == other.text;

  @override
  int get hashCode =>
      super.hashCode ^
      maxTextWidth.hashCode ^
      paintBack.hashCode ^
      paintFront.hashCode ^
      position.hashCode ^
      text.hashCode;

  @override
  String toString() {
    return 'PointTextContainer{maxTextWidth: $maxTextWidth, paintBack: $paintBack, paintFront: $paintFront, position: $position, text: $text, ${super.toString()}';
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }
}
