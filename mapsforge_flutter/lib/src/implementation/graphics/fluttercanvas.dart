import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
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
    uiCanvas.drawLine(ui.Offset(x1.toDouble(), y1.toDouble()), ui.Offset(x2.toDouble(), y2.toDouble()), (paint as FlutterPaint).paint);
  }

  @override
  void drawPath(MapPath path, MapPaint paint) {
    uiCanvas.drawPath((path as FlutterPath).path, (paint as FlutterPaint).paint);
  }

  @override
  void drawPathText(String text, LineString lineString, Mappoint origin, MapPaint paint) {
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 10.0,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(ui.TextStyle(color: ui.Color((paint as FlutterPaint).getColor())))
      ..addText(text);

    ui.Paragraph paragraph = builder.build();

    LineSegment firstSegment = lineString.segments.elementAt(0);
    // So text isn't upside down
    bool doInvert = firstSegment.end.x <= firstSegment.start.x;

    double textlen = (text.length * 50).toDouble();

    //uiCanvas.transform(new Matrix4.identity().rotatestorage);

    if (!doInvert) {
      Mappoint start = firstSegment.start.offset(-origin.x, -origin.y);
      uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(start.x - textlen / 2, start.y));
      for (int i = 0; i < lineString.segments.length; i++) {
        LineSegment segment = lineString.segments.elementAt(i);
        Mappoint end = segment.end.offset(-origin.x, -origin.y);
        uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(end.x - textlen / 2, end.y));
      }
    } else {
      Mappoint end = lineString.segments.elementAt(lineString.segments.length - 1).end.offset(-origin.x, -origin.y);
      uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(end.x - textlen / 2, end.y));
      for (int i = lineString.segments.length - 1; i >= 0; i--) {
        LineSegment segment = lineString.segments.elementAt(i);
        Mappoint start = segment.start.offset(-origin.x, -origin.y);
        uiCanvas.drawParagraph(paragraph..layout(ui.ParagraphConstraints(width: textlen)), Offset(start.x - textlen / 2, start.y));
      }
    }
  }

  @override
  void drawText(String text, int x, int y, double fontSize, MapPaint paint) {
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: fontSize,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(ui.TextStyle(color: ui.Color(paint.getColor())))
      ..addText(text);
    double width = text.length * 5 * fontSize;
    uiCanvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: width)), Offset(x.toDouble() - width / 2, y.toDouble()));
  }

  @override
  void drawTextRotated(String text, int x1, int y1, int x2, int y2, MapPaint paint) {
    // TODO: implement drawTextRotated
  }

  @override
  void fillColor(Color color) {
    // TODO: implement fillColor
  }
}
