import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:ecache/ecache.dart';
import 'package:flutter/rendering.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/linesegment.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import 'flutterbitmap.dart';
import 'fluttermatrix.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'flutterrect.dart';
import 'fluttertilebitmap.dart';

class FlutterCanvas extends MapCanvas {
  //static final _log = new Logger('FlutterCanvas');

  late ui.Canvas uiCanvas;

  ui.PictureRecorder? pictureRecorder;

  /// The size of the canvas
  final ui.Size size;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String? src;

  int actions = 0;

  static LruCache<String, double> _cache = new LruCache<String, double>(
    storage: SimpleStorage<String, double>(),
    capacity: 2000,
  );

  FlutterCanvas(this.uiCanvas, this.size, [this.src]) : pictureRecorder = null;

  FlutterCanvas.forRecorder(double width, double height, [this.src])
      : pictureRecorder = ui.PictureRecorder(),
        size = ui.Size(width, height),
        assert(width >= 0),
        assert(height >= 0) {
    uiCanvas = ui.Canvas(pictureRecorder!);
    //uiCanvas.clipRect(Rect.fromLTWH(0, 0, width, height), doAntiAlias: true);
  }

  @override
  void destroy() {
    if (pictureRecorder != null) pictureRecorder!.endRecording();
  }

  @override
  void drawBitmap(
      {required Bitmap bitmap,
      required double left,
      required double top,
      required MapPaint paint,
      int? srcLeft,
      int? srcTop,
      int? srcRight,
      int? srcBottom,
      int? dstLeft,
      int? dstTop,
      int? dstRight,
      int? dstBottom,
      Matrix? matrix,
      Filter? filter}) {
    ui.Image bmp = (bitmap as FlutterBitmap).bitmap;
    assert(bmp.width > 0);
    assert(bmp.height > 0);
    if (matrix != null) {
      FlutterMatrix f = matrix as FlutterMatrix;
      if (f.theta != null) {
        // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
        double angle = f.theta!; // 30 * pi / 180
        final double r = sqrt(f.pivotX! * f.pivotX! + f.pivotY! * f.pivotY!);
        final double alpha = f.pivotX == 0
            ? pi / 90 * f.pivotY!.sign
            : atan(f.pivotY! / f.pivotX!);
        final double beta = alpha + angle;
        final shiftY = r * sin(beta);
        final shiftX = r * cos(beta);
        final translateX = f.pivotX! - shiftX;
        final translateY = f.pivotY! - shiftY;
        uiCanvas.save();
        uiCanvas.translate(translateX + left, translateY + top);
        uiCanvas.rotate(angle);
        uiCanvas.drawImage(bmp, ui.Offset.zero, (paint as FlutterPaint).paint);
        uiCanvas.restore();
        ++actions;
        return;
      }
    }
    //_log.info("Drawing image to $left/$top " + (bitmap as FlutterBitmap).bitmap.toString());
    if (left + bmp.width < 0 ||
        top + bmp.height < 0 ||
        left - bmp.width > size.width ||
        top - bmp.height > size.height) return;
    uiCanvas.drawImage(
        bmp, ui.Offset(left, top), (paint as FlutterPaint).paint);
    ++actions;
  }

  @override
  void fillColorFromNumber(int color) {
    ui.Paint paint = ui.Paint()..color = ui.Color(color);
    this
        .uiCanvas
        .drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), paint);
    ++actions;
  }

  @override
  void setClip(double left, double top, double width, double height) {
    uiCanvas.clipRect(ui.Rect.fromLTWH(left, top, width, height),
        doAntiAlias: true);
    ++actions;
  }

  @override
  Future<Bitmap> finalizeBitmap() async {
    ui.Picture pic = pictureRecorder!.endRecording();
    ui.Image img = await pic.toImage(size.width.ceil(), size.height.ceil());
    pictureRecorder = null;
    pic.dispose();

    return FlutterTileBitmap(img, src);
  }

  @override
  void drawCircle(double x, double y, double radius, MapPaint paint) {
    //_log.info("draw circle at $x $y $radius $paint at ${ui.Offset(x.toDouble(), y.toDouble())}");
    uiCanvas.drawCircle(ui.Offset(x, y), radius, (paint as FlutterPaint).paint);
    ++actions;
  }

  @override
  void drawLine(double x1, double y1, double x2, double y2, MapPaint paint) {
    //_log.info("draw line at $x1 $y1 $x2 $y2 $paint}");
    Path path = new Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);

    drawPath(new FlutterPath(path), paint);
  }

  @override
  void drawPath(MapPath path, MapPaint paint) {
    List<double>? dasharray = paint.getStrokeDasharray();
    if (dasharray != null && dasharray.length >= 2) {
      Path dashPath = Path();
      PathMetrics pathMetrics = (path as FlutterPath).path.computeMetrics();
      for (PathMetric pathMetric in pathMetrics) {
        double distance = 0;
        while (distance < pathMetric.length) {
          for (int i = 0; i < dasharray.length; i += 2) {
            double dashLength = dasharray[i];
            double gapLength = dasharray[i + 1];
            if (dashLength > 0) {
              dashPath.addPath(
                pathMetric.extractPath(distance, distance + dashLength),
                Offset.zero,
              );
            }
            distance += dashLength + gapLength;
          }
        }
      }
      uiCanvas.drawPath(dashPath, (paint as FlutterPaint).paint);
      ++actions;
    } else {
      //_log.info("draw path at ${(path as FlutterPath).path.getBounds()}  $paint}");
      uiCanvas.drawPath(
          (path as FlutterPath).path, (paint as FlutterPaint).paint);
      ++actions;
    }
  }

  @override
  void drawRect(MapRect rect, MapPaint paint) {
    if (rect.getBottom() < 0 ||
        rect.getRight() < 0 ||
        rect.getLeft() > size.width ||
        rect.getTop() > size.height) return;
    Rect rt = (rect as FlutterRect).rect;
    //FlutterPaint pt = (paint as FlutterPaint).paint;
    if (paint.getStrokeDasharray() != null &&
        paint.getStrokeDasharray()!.length >= 2) {
      Path rectPath = Path()..addRect(rt);
      drawPath(new FlutterPath(rectPath), paint);
    } else {
      uiCanvas.drawRect(rt, (paint as FlutterPaint).paint);
      ++actions;
    }
  }

  @override
  void drawPathText(String text, LineString lineString, Mappoint origin,
      MapPaint paint, MapTextPaint mapTextPaint) {
    if (text.trim().isEmpty) {
      return;
    }
    if (paint.isTransparent()) {
      return;
    }
    double fontSize = mapTextPaint.getTextSize();
    ui.ParagraphBuilder builder =
        buildParagraphBuilder(text, paint, mapTextPaint);

    ui.Paragraph paragraph = builder.build();

    double textwidth = calculateTextWidth(text, mapTextPaint);

//    double len = 0;
    lineString.segments.forEach((segment) {
      // double segmentLength = segment.length();
      // if (segmentLength < textlen) {
      //   // do not draw the text on a short path because the text does not wrap around the path. It would look ugly if the next segment changes its
      //   // direction significantly
      //   len -= segmentLength;
      //   return;
      // }
//      len = textlen + fontSize * 2;
      // So text isn't upside down
      bool doInvert = segment.end.x <= segment.start.x;
      Mappoint start = doInvert
          ? segment.end.offset(-origin.x, -origin.y)
          : segment.start.offset(-origin.x, -origin.y);
      _drawTextRotated(
          paragraph, textwidth, fontSize, segment, start, doInvert);
//      len -= segmentLength;
    });
  }

  void _drawTextRotated(ui.Paragraph paragraph, double textwidth,
      double fontSize, LineSegment segment, Mappoint start, bool doInvert) {
    // since the text is rotated, use the textwidth as margin in all directions
    if (start.x + textwidth < 0 ||
        start.y + textwidth < 0 ||
        start.x - textwidth > size.width ||
        start.y - textwidth > size.height) return;
    double theta = segment.getTheta();

    // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
    double angle = theta; // 30 * pi / 180
//    final double r = sqrt(textlen * textlen / 4 + fontSize * fontSize / 4);
//    final double alpha = textlen == 0 ? pi / 90 * fontSize.sign : atan(fontSize / textlen);
//    final double beta = alpha + angle;
//    final shiftY = r * sin(beta);
//    final shiftX = r * cos(beta);
//    final translateX = textlen - shiftX;
//    final translateY = fontSize - shiftY;
    //print("drawing $segment for $textwidth $doInvert ${paragraph} $angle");
    uiCanvas.save();
    uiCanvas.translate(/*translateX +*/ start.x, /*translateY +*/ start.y);
    uiCanvas.rotate(angle);
    uiCanvas.translate(0, -fontSize / 2);
    uiCanvas.drawParagraph(
        paragraph..layout(ui.ParagraphConstraints(width: textwidth)),
        const Offset(0, 0));
    uiCanvas.restore();
    ++actions;
  }

  @override
  void drawText(String text, double x, double y, MapPaint paint,
      MapTextPaint mapTextPaint) {
    double textwidth = calculateTextWidth(text, mapTextPaint);
    if (x + textwidth / 2 < 0 ||
        y + mapTextPaint.getTextSize() < 0 ||
        x - textwidth / 2 > size.width ||
        y - mapTextPaint.getTextSize() > size.height) return;
    ui.ParagraphBuilder builder =
        buildParagraphBuilder(text, paint, mapTextPaint);
    uiCanvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: textwidth)),
        Offset(x - textwidth / 2, y));
    ++actions;
  }

  static double calculateTextWidth(String text, MapTextPaint mapTextPaint) {
    String key =
        "$text-${mapTextPaint.getTextSize()}-${mapTextPaint.getFontStyle().name}";
    double? result = _cache.get(key);
    if (result != null) return result;

    // https://stackoverflow.com/questions/52659759/how-can-i-get-the-size-of-the-text-widget-in-flutter/52991124#52991124
    // self-defined constraint
    final constraints = const BoxConstraints(
      maxWidth: 800.0, // maxwidth calculated
      minHeight: 0.0,
      minWidth: 0.0,
    );

    RenderParagraph renderParagraph = RenderParagraph(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: mapTextPaint.getTextSize(),
          fontStyle: mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC ||
                  mapTextPaint.getFontStyle() == MapFontStyle.ITALIC
              ? FontStyle.italic
              : FontStyle.normal,
          fontWeight: mapTextPaint.getFontStyle() == MapFontStyle.BOLD ||
                  mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    renderParagraph.layout(constraints);
    double textlen = renderParagraph
        .getMinIntrinsicWidth(mapTextPaint.getTextSize())
        .ceilToDouble();
//    _log.info("Textlen: $textlen for $text");
    _cache.set(key, textlen);
    return textlen;
  }

  static ui.ParagraphBuilder buildParagraphBuilder(
      String text, MapPaint paint, MapTextPaint mapTextPaint) {
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: mapTextPaint.getTextSize(),
        //textAlign: TextAlign.center,
        fontStyle: mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC ||
                mapTextPaint.getFontStyle() == MapFontStyle.ITALIC
            ? ui.FontStyle.italic
            : ui.FontStyle.normal,
        fontWeight: mapTextPaint.getFontStyle() == MapFontStyle.BOLD ||
                mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC
            ? ui.FontWeight.bold
            : ui.FontWeight.normal,
        //fontFamily: _fontFamily == MapFontFamily.MONOSPACE ? FontFamily.MONOSPACE : FontFamily.DEFAULT,
      ),
    );

    if (paint.getStrokeWidth() == 0)
      builder.pushStyle(ui.TextStyle(
        color: paint.getColor(),
        fontFamily: mapTextPaint
            .getFontFamily()
            .toString()
            .replaceAll("MapFontFamily.", ""),
      ));
    else
      builder.pushStyle(ui.TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.getStrokeWidth()
          ..color = paint.getColor(),
        fontFamily: mapTextPaint
            .getFontFamily()
            .toString()
            .replaceAll("MapFontFamily.", ""),
      ));

    builder.addText(text);
    return builder;
  }

  @override
  void scale(Mappoint focalPoint, double scale) {
    double diffX = size.width / 2 - focalPoint.x;
    double diffY = size.height / 2 - focalPoint.y;
    uiCanvas.translate((-size.width / 2 + diffX) * (scale - 1),
        (-size.height / 2 + diffY) * (scale - 1));
    // This method scales starting from the top/left corner. That means that the top-left corner stays at its position and the rest is scaled.
    uiCanvas.scale(scale);
    ++actions;
  }
}
