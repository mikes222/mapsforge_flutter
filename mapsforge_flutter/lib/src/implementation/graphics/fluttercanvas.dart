import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/linesegment.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/rectangle.dart';

import 'flutterbitmap.dart';
import 'fluttermatrix.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'flutterrect.dart';
import 'fluttertilebitmap.dart';

class FlutterCanvas extends MapCanvas {
  static final _log = new Logger('FlutterCanvas');

  ui.Canvas uiCanvas;

  ui.PictureRecorder pictureRecorder;

  final ui.Size size;

  FlutterCanvas(this.uiCanvas, this.size)
      : assert(uiCanvas != null),
        pictureRecorder = null;

  FlutterCanvas.forRecorder(double width, double height)
      : pictureRecorder = ui.PictureRecorder(),
        size = ui.Size(width, height),
        assert(width >= 0),
        assert(height >= 0) {
    uiCanvas = ui.Canvas(pictureRecorder);
  }

  @override
  void destroy() {
    if (pictureRecorder != null) pictureRecorder.endRecording();
  }

  @override
  void drawBitmap(
      {@required Bitmap bitmap,
      @required double left,
      @required double top,
      @required MapPaint paint,
      int srcLeft,
      int srcTop,
      int srcRight,
      int srcBottom,
      int dstLeft,
      int dstTop,
      int dstRight,
      int dstBottom,
      Matrix matrix,
      Filter filter}) {
    assert(bitmap != null);
    assert(left != null);
    assert(top != null);
    assert(paint != null);

    ui.Image bmp = (bitmap as FlutterBitmap).bitmap;
    assert(bmp != null);
    assert(bmp.width > 0);
    assert(bmp.height > 0);
    if (matrix != null) {
      FlutterMatrix f = matrix;
      if (f.theta != null) {
        // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
        double angle = f.theta; // 30 * pi / 180
        final double r = sqrt(f.pivotX * f.pivotX + f.pivotY * f.pivotY);
        final double alpha = f.pivotX == 0 ? pi / 90 * f.pivotY.sign : atan(f.pivotY / f.pivotX);
        final double beta = alpha + angle;
        final shiftY = r * sin(beta);
        final shiftX = r * cos(beta);
        final translateX = f.pivotX - shiftX;
        final translateY = f.pivotY - shiftY;
        uiCanvas.save();
        uiCanvas.translate(translateX + left, translateY + top);
        uiCanvas.rotate(angle);
        uiCanvas.drawImage(bmp, ui.Offset.zero, (paint as FlutterPaint).paint);
        uiCanvas.restore();
        return;
      }
    }
    //paint.color = Colors.red;
    //_log.info("Drawing image to $left/$top " + (bitmap as FlutterBitmap).bitmap.toString());
    uiCanvas.drawImage(bmp, ui.Offset(left, top), (paint as FlutterPaint).paint);
  }

  @override
  void fillColorFromNumber(int color) {
    ui.Paint paint = ui.Paint()..color = ui.Color(color);
    this.uiCanvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  Dimension getDimension() {
    // TODO: implement getDimension
    return null;
  }

  @override
  int getHeight() {
    // TODO: implement getHeight
    return null;
  }

  @override
  int getWidth() {
    // TODO: implement getWidth
    return null;
  }

  @override
  bool isAntiAlias() {
    // TODO: implement isAntiAlias
    return null;
  }

  @override
  bool isFilterBitmap() {
    // TODO: implement isFilterBitmap
    return null;
  }

  @override
  void resetClip() {}

  @override
  void setAntiAlias(bool aa) {
    // TODO: implement setAntiAlias
  }

  @override
  void setBitmap(Bitmap bitmap) {
    // TODO: implement setBitmap
  }

  @override
  void setClip(int left, int top, int width, int height) {
    uiCanvas.clipRect(ui.Rect.fromLTWH(left.toDouble(), top.toDouble(), width.toDouble(), height.toDouble()));
  }

  @override
  void setClipDifference(int left, int top, int width, int height) {
    // TODO: implement setClipDifference
  }

  @override
  void setFilterBitmap(bool filter) {
    // TODO: implement setFilterBitmap
  }

  @override
  void shadeBitmap(Bitmap bitmap, Rectangle shadeRect, Rectangle tileRect, double magnitude) {
    // TODO: implement shadeBitmap
  }

  @override
  Future<Bitmap> finalizeBitmap() async {
    ui.Picture pic = pictureRecorder.endRecording();
    assert(pic != null);
    ui.Image img = await pic.toImage(size.width.toInt(), size.height.toInt());
    assert(img != null);
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();
    pictureRecorder = null;

    return FlutterTileBitmap(img);
  }

  @override
  void drawCircle(int x, int y, int radius, MapPaint paint) {
    uiCanvas.drawCircle(ui.Offset(x.toDouble(), y.toDouble()), radius.toDouble(), (paint as FlutterPaint).paint);
  }

  @override
  void drawLine(int x1, int y1, int x2, int y2, MapPaint paint) {
    Path path = new Path()
      ..moveTo(x1.toDouble(), y1.toDouble())
      ..lineTo(x2.toDouble(), y2.toDouble());

    drawPath(new FlutterPath(path), paint);
  }

  @override
  void drawPath(MapPath path, MapPaint paint) {
    List<double> dasharray = paint.getStrokeDasharray();
    if (dasharray != null && dasharray.length >= 2) {
      Path dashPath = Path();
      PathMetrics pathMetrics = (path as FlutterPath).path.computeMetrics();
      for (PathMetric pathMetric in pathMetrics) {
        double distance = 0;
        while (distance < pathMetric.length) {
          for (int i = 0; i < dasharray.length; i += 2) {
            double dashLength = dasharray[i];
            double gapLength = dasharray[i + 1];
            dashPath.addPath(
              pathMetric.extractPath(distance, distance + dashLength),
              Offset.zero,
            );
            distance += dashLength + gapLength;
          }
        }
      }
      uiCanvas.drawPath(dashPath, (paint as FlutterPaint).paint);
    } else
      uiCanvas.drawPath((path as FlutterPath).path, (paint as FlutterPaint).paint);
  }

  @override
  void drawRect(MapRect rect, MapPaint paint) {
    Rect rt = (rect as FlutterRect).rect;
    //FlutterPaint pt = (paint as FlutterPaint).paint;
    if (paint.getStrokeDasharray() != null && paint.getStrokeDasharray().length >= 2) {
      Path rectPath = Path()..addRect(rt);
      drawPath(new FlutterPath(rectPath), paint);
    } else
      uiCanvas.drawRect(rt, (paint as FlutterPaint).paint);
  }

  @override
  void drawPathText(String text, LineString lineString, Mappoint origin, MapPaint paint) {
    if (text == null || text.trim().isEmpty) {
      return;
    }
    if (paint.isTransparent()) {
      return;
    }
    double fontSize = paint.getTextSize();
    ui.ParagraphBuilder builder = (paint as FlutterPaint).buildParagraphBuilder(text);

    ui.Paragraph paragraph = builder.build();

    LineSegment firstSegment = lineString.segments.elementAt(0);
    // So text isn't upside down
    bool doInvert = firstSegment.end.x <= firstSegment.start.x;

    double textlen = calculateTextWidth(text, fontSize, paint);

    //uiCanvas.transform(new Matrix4.identity().rotatestorage);

    if (!doInvert) {
      double len = 0;
//      Mappoint start = firstSegment.start.offset(-origin.x, -origin.y);
//      //uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(start.x - textlen / 2, start.y));
//      _drawTextRotated(paragraph, textlen, fontSize, firstSegment, start);
//      len -= sqrt((firstSegment.end.x - firstSegment.start.x) * (firstSegment.end.x - firstSegment.start.x) +
//          (firstSegment.end.y - firstSegment.start.y) * (firstSegment.end.y - firstSegment.start.y));
      for (int i = 0; i < lineString.segments.length; i++) {
        LineSegment segment = lineString.segments.elementAt(i);
        double segmentLength = sqrt((segment.end.x - segment.start.x) * (segment.end.x - segment.start.x) +
            (segment.end.y - segment.start.y) * (segment.end.y - segment.start.y));
        if (segmentLength < textlen * 2 / 3) {
          // do not draw the text on a short path because the text does not wrap around the path. It would look ugly if the next segment changes its
          // direction significantly
          len -= segmentLength;
          continue;
        }
        if (len > 0) {
          len -= segmentLength;
          continue;
        }
        len = textlen + fontSize * 2;
        Mappoint start = segment.start.offset(-origin.x, -origin.y);
        _drawTextRotated(paragraph, textlen, fontSize, segment, start, doInvert);
        len -= segmentLength;
      }
    } else {
      double len = 0;
//      Mappoint end = lineString.segments.elementAt(lineString.segments.length - 1).end.offset(-origin.x, -origin.y);
//      //uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(end.x - textlen / 2, end.y));
//      _drawTextRotated(paragraph, textlen, fontSize, firstSegment, end);
//      len -= sqrt((firstSegment.end.x - firstSegment.start.x) * (firstSegment.end.x - firstSegment.start.x) +
//          (firstSegment.end.y - firstSegment.start.y) * (firstSegment.end.y - firstSegment.start.y));
      for (int i = lineString.segments.length - 1; i >= 0; i--) {
        LineSegment segment = lineString.segments.elementAt(i);
        double segmentLength = sqrt((segment.end.x - segment.start.x) * (segment.end.x - segment.start.x) +
            (segment.end.y - segment.start.y) * (segment.end.y - segment.start.y));
        if (segmentLength < textlen * 2 / 3) {
          // do not draw the text on a short path because the text does not wrap around the path. It would look ugly if the next segment changes its
          // direction significantly
          len -= segmentLength;
          continue;
        }
        if (len > 0) {
          len -= segmentLength;
          continue;
        }
        len = textlen + fontSize * 2;
        Mappoint end = segment.end.offset(-origin.x, -origin.y);
        _drawTextRotated(paragraph, textlen, fontSize, segment, end, doInvert);
        len -= segmentLength;
      }
    }
  }

  static double calculateTextWidth(String text, double fontSize, MapPaint paint) {
    // https://stackoverflow.com/questions/52659759/how-can-i-get-the-size-of-the-text-widget-in-flutter/52991124#52991124
    // self-defined constraint
    final constraints = BoxConstraints(
      maxWidth: 800.0, // maxwidth calculated
      minHeight: 0.0,
      minWidth: 0.0,
    );

    RenderParagraph renderParagraph = RenderParagraph(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontStyle: paint.getFontStyle() == MapFontStyle.BOLD_ITALIC || paint.getFontStyle() == MapFontStyle.ITALIC
              ? FontStyle.italic
              : FontStyle.normal,
          fontWeight: paint.getFontStyle() == MapFontStyle.BOLD || paint.getFontStyle() == MapFontStyle.BOLD_ITALIC
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    renderParagraph.layout(constraints);
    double textlen = renderParagraph.getMinIntrinsicWidth(fontSize).ceilToDouble(); // + 1;
//    _log.info("Textlen: $textlen for $text");
    return textlen;
  }

  void _drawTextRotated(ui.Paragraph paragraph, double textlen, double fontSize, LineSegment segment, Mappoint end, bool doInvert) {
    double theta = segment.end.x != segment.start.x ? atan((segment.end.y - segment.start.y) / (segment.end.x - segment.start.x)) : pi;
    Paint paint = ui.Paint();
    paint.color = (Colors.cyanAccent);

    // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
    double angle = theta; // 30 * pi / 180
//    final double r = sqrt(textlen * textlen / 4 + fontSize * fontSize / 4);
//    final double alpha = textlen == 0 ? pi / 90 * fontSize.sign : atan(fontSize / textlen);
//    final double beta = alpha + angle;
//    final shiftY = r * sin(beta);
//    final shiftX = r * cos(beta);
//    final translateX = textlen - shiftX;
//    final translateY = fontSize - shiftY;
    uiCanvas.save();
    uiCanvas.translate(/*translateX +*/ end.x, /*translateY +*/ end.y);
    uiCanvas.rotate(angle);
    uiCanvas.translate(0, -fontSize / 2);
    //uiCanvas.drawRect(ui.Rect.fromLTWH(0, 0, textlen, fontSize), paint);
    //uiCanvas.drawCircle(Offset.zero, 10, paint);
    uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(0, 0));
    uiCanvas.restore();
  }

  @override
  void drawText(String text, int x, int y, MapPaint paint) {
    double textwidth = calculateTextWidth(text, paint.getTextSize(), paint);
    ui.ParagraphBuilder builder = (paint as FlutterPaint).buildParagraphBuilder(text);
    uiCanvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: textwidth)), Offset(x.toDouble() - textwidth / 2, y.toDouble()));
  }

  @override
  void drawTextRotated(String text, int x1, int y1, int x2, int y2, MapPaint paint) {
    // TODO: implement drawTextRotated
  }

  @override
  void fillColor(Color color) {
    // TODO: implement fillColor
  }

  @override
  void scale(Mappoint focalPoint, double scale) {
    uiCanvas.save();
    uiCanvas.translate(focalPoint.x, focalPoint.y);
    uiCanvas.scale(scale);
    uiCanvas.translate(-focalPoint.x, -focalPoint.y);
  }
}
