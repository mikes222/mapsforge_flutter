import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/mapelements/pointtextcontainer.dart';
import 'package:mapsforge_flutter/src/mapelements/symbolcontainer.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/rectangle.dart';

import 'fluttercanvas.dart';

class FlutterPointTextContainer extends PointTextContainer {
//  StaticLayout backLayout;
//  StaticLayout frontLayout;

  ui.ParagraphBuilder builder;

  FlutterPointTextContainer(Mappoint xy, Display display, int priority, String text, MapPaint paintFront, MapPaint paintBack,
      SymbolContainer symbolContainer, Position position, int maxTextWidth)
      : super(xy, display, priority, text, paintFront, paintBack, symbolContainer, position, maxTextWidth) {
    double boxWidth;
    double boxHeight;

    // TextPaint frontTextPaint = new TextPaint(AndroidGraphicFactory.getPaint(this.paintFront));
    //TextPaint backTextPaint = null;
    if (this.paintBack != null) {
      //backTextPaint = new TextPaint(AndroidGraphicFactory.getPaint(this.paintBack));
    }

    ui.TextAlign alignment = ui.TextAlign.center;
    if (Position.LEFT == this.position || Position.BELOW_LEFT == this.position || Position.ABOVE_LEFT == this.position) {
      //alignment = Layout.Alignment.ALIGN_OPPOSITE;
    } else if (Position.RIGHT == this.position || Position.BELOW_RIGHT == this.position || Position.ABOVE_RIGHT == this.position) {
      //alignment = Layout.Alignment.ALIGN_NORMAL;
    }

    // strange Android behaviour: if alignment is set to center, then
    // text is rendered with right alignment if using StaticLayout

    builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 14.0,
        textAlign: alignment,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: ui.Color(paintFront.getColor()),
      ))
      ..addText(text);

    if (this.paintBack != null) {
      //backTextPaint.setTextAlign(android.graphics.Paint.Align.LEFT);
    }

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

    boxWidth = textWidth.toDouble();
    boxHeight = textHeight.toDouble();

    switch (this.position) {
      case Position.CENTER:
        boundary = new Rectangle(-boxWidth / 2, -boxHeight / 2, boxWidth / 2, boxHeight / 2);
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
      default:
        break;
    }
  }

  @override
  void draw(MapCanvas canvas, Mappoint origin, Matrix matrix, Filter filter) {
    if (!this.isVisible) {
      return;
    }

    ui.Canvas flutterCanvas = (canvas as FlutterCanvas).uiCanvas;

    // the origin of the text is the base line, so we need to make adjustments
    // so that the text will be within its box
    double textOffset = 0;
    switch (this.position) {
      case Position.CENTER:
      case Position.LEFT:
      case Position.RIGHT:
        textOffset = textHeight / 2;
        break;
      case Position.BELOW:
      case Position.BELOW_LEFT:
      case Position.BELOW_RIGHT:
        textOffset = textHeight.toDouble();
        break;
      default:
        break;
    }

    double adjustedX = (this.xy.x - origin.x) + boundary.left;
    double adjustedY = (this.xy.y - origin.y) + textOffset + boundary.top;

//    if (this.paintBack != null) {
//      int color = this.paintBack.getColor();
//      if (filter != Filter.NONE) {
//        this.paintBack.setColor(GraphicUtils.filterColor(color, filter));
//      }
//      flutterCanvas.drawText(this.text, adjustedX, adjustedY, FlutterGraphicFactory.getPaint(this.paintBack));
//      if (filter != Filter.NONE) {
//        this.paintBack.setColor(color);
//      }
//    }
//    int color = this.paintFront.getColor();
//    if (filter != Filter.NONE) {
//      this.paintFront.setColor(GraphicUtils.filterColor(color, filter));
//    }
    flutterCanvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: textWidth.toDouble())), Offset(adjustedX, adjustedY));
//    if (filter != Filter.NONE) {
//      this.paintFront.setColor(color);
//    }
  }
}
