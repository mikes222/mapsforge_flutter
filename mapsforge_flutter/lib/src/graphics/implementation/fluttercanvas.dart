import 'dart:ui' as ui;
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/paragraph_cache.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import 'flutterbitmap.dart';
import 'fluttermatrix.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'flutterrect.dart';
import 'fluttertilebitmap.dart';

class FlutterCanvas extends MapCanvas {
  static final _log = new Logger('FlutterCanvas');

  late ui.Canvas uiCanvas;

  ui.PictureRecorder? pictureRecorder;

  /// The size of the canvas
  final ui.Size size;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String? src;

  int actions = 0;

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
  void drawBitmap({
    required Bitmap bitmap,
    required double left,
    required double top,
    required MapPaint paint,
    Matrix? matrix,
  }) {
    ui.Image image = (bitmap as FlutterBitmap).getClonedImage();
    assert(image.width > 0);
    assert(image.height > 0);
    if (matrix != null) {
      FlutterMatrix fm = matrix as FlutterMatrix;
      if (fm.theta != null) {
        uiCanvas.save();
        uiCanvas.translate(left, top);
        uiCanvas.translate(-fm.pivotX!, -fm.pivotY!);
        // uiCanvas.drawCircle(
        //     const ui.Offset(0, 0), 5, ui.Paint()..color = Colors.blue);
        uiCanvas.rotate(fm.theta!);
        uiCanvas.translate(fm.pivotX!, fm.pivotY!);
        // uiCanvas.drawRect(
        //     ui.Rect.fromLTWH(
        //         0, 0, image.width.toDouble(), image.height.toDouble()),
        //     ui.Paint()..color = Colors.red.withOpacity(0.7));
        // uiCanvas.drawCircle(
        //     const ui.Offset(0, 0), 10, ui.Paint()..color = Colors.green);
        uiCanvas.drawImage(
            image, ui.Offset.zero, (paint as FlutterPaint).paint);
        uiCanvas.restore();
        image.dispose();
        ++actions;
        return;
      }
    }
    // _log.info(
    //     "Drawing image to $left/$top (${image.width} / ${image.height}) $bitmap, $matrix");
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(
    //         left, top, image.width.toDouble(), image.height.toDouble()),
    //     ui.Paint()..color = Colors.red);
    // uiCanvas.drawCircle(
    //     ui.Offset(left, top), 10, ui.Paint()..color = Colors.green);
    uiCanvas.drawImage(
        image, ui.Offset(left, top), (paint as FlutterPaint).paint);
    image.dispose();
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
      MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth) {
    if (text.trim().isEmpty) {
      return;
    }
    if (paint.isTransparent()) {
      return;
    }

    ParagraphEntry entry =
        ParagraphCache().getEntry(text, mapTextPaint, paint, maxTextWidth);

    lineString.segments.forEach((segment) {
      // So text isn't upside down
      bool doInvert = segment.end.x < segment.start.x;
      Mappoint start;
      double diff = (segment.length() - entry.getWidth()) / 2;
      if (doInvert) {
        //start = segment.end.offset(-origin.x, -origin.y);
        start = segment
            .pointAlongLineSegment(diff + entry.getWidth())
            .offset(-origin.x, -origin.y);
      } else {
        //start = segment.start.offset(-origin.x, -origin.y);
        start =
            segment.pointAlongLineSegment(diff).offset(-origin.x, -origin.y);
      }
      // print(
      //     "$text: segment length ${segment.length()} - word length ${entry.getWidth()} at ${start.x - segment.start.x} / ${start.y - segment.start.y} @ ${segment.getAngle()}");
      _drawTextRotated(entry.paragraph, segment.getTheta(), start);
//      len -= segmentLength;
    });
  }

  void _drawTextRotated(ui.Paragraph paragraph, double theta, Mappoint start) {
    // since the text is rotated, use the textwidth as margin in all directions
    // if (start.x + textwidth < 0 ||
    //     start.y + textwidth < 0 ||
    //     start.x - textwidth > size.width ||
    //     start.y - textwidth > size.height) return;
    //double theta = segment.getTheta();

    // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
    uiCanvas.save();
    uiCanvas.translate(/*translateX +*/ start.x, /*translateY +*/ start.y);
    uiCanvas.rotate(theta);
    uiCanvas.translate(0, -paragraph.height / 2);
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(0, 0, paragraph.longestLine, paragraph.height),
    //     ui.Paint()..color = Colors.red);
    // uiCanvas.drawCircle(Offset.zero, 10, ui.Paint()..color = Colors.green);
    uiCanvas.drawParagraph(paragraph, Offset.zero);
    uiCanvas.restore();
    ++actions;
  }

  /// draws the given [text] so that the center of the text in at the given x/y coordinates
  @override
  void drawText(String text, double x, double y, MapPaint paint,
      MapTextPaint mapTextPaint, double maxTextWidth) {
    ParagraphEntry entry =
        ParagraphCache().getEntry(text, mapTextPaint, paint, maxTextWidth);
    double textwidth = entry.getWidth();
    double textHeight = entry.getHeight();
    if (x + textwidth / 2 < 0 ||
        y + entry.getHeight() < 0 ||
        x - textwidth / 2 > size.width ||
        y - entry.getHeight() > size.height) return;
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(x - textwidth / 2, y - textHeight / 2,
    //         entry.getWidth(), entry.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.7));
    // uiCanvas.drawCircle(ui.Offset(x - textwidth / 2, y - textHeight / 2), 10,
    //     ui.Paint()..color = Colors.green);
    uiCanvas.drawParagraph(
        entry.paragraph, Offset(x - textwidth / 2, y - textHeight / 2));
    // uiCanvas.drawCircle(ui.Offset(x, y), 5, ui.Paint()..color = Colors.blue);
    ++actions;
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
