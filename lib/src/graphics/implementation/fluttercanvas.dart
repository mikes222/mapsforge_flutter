import 'dart:ui' as ui;
import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilepicture.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/paragraph_cache.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

import '../../model/relative_mappoint.dart';
import '../tilepicture.dart';
import 'flutterbitmap.dart';
import 'fluttermatrix.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'flutterrect.dart';

class FlutterCanvas extends MapCanvas {
  late ui.Canvas uiCanvas;

  ui.PictureRecorder? _pictureRecorder;

  /// The size of the canvas
  final ui.Size size;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String? src;

  int _actions = 0;

  int _bitmapCount = 0;

  int _textCount = 0;

  int _pathCount = 0;

  FlutterCanvas(this.uiCanvas, this.size, [this.src]) : _pictureRecorder = null;

  FlutterCanvas.forRecorder(double width, double height, [this.src])
      : _pictureRecorder = ui.PictureRecorder(),
        size = ui.Size(width, height),
        assert(width >= 0),
        assert(height >= 0) {
    uiCanvas = ui.Canvas(_pictureRecorder!);
    //uiCanvas.clipRect(Rect.fromLTWH(0, 0, width, height), doAntiAlias: true);
  }

  @override
  void destroy() {
    if (_pictureRecorder != null) _pictureRecorder!.endRecording();
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
        uiCanvas.drawImage(image, ui.Offset.zero, (paint as FlutterPaint).paint);
        uiCanvas.restore();
        image.dispose();
        ++_bitmapCount;
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
    uiCanvas.drawImage(image, ui.Offset(left, top), (paint as FlutterPaint).paint);
    image.dispose();
    ++_bitmapCount;
  }

  @override
  void drawTilePicture({
    required TilePicture picture,
    required double left,
    required double top,
  }) {
    if (picture.getPicture() != null) {
      ui.Picture pic = picture.getPicture()!;
      uiCanvas.save();
      uiCanvas.translate(left, top);
      double tileSize = MapsforgeConstants().tileSize;
      uiCanvas.clipRect(ui.Rect.fromLTWH(0, 0, tileSize, tileSize));
      uiCanvas.drawPicture(pic);
      uiCanvas.restore();
      //picture.dispose();
    } else {
      ui.Image image = picture.getClonedImage()!;
      uiCanvas.drawImage(image, ui.Offset(left, top), ui.Paint());
      image.dispose();
    }
    ++_bitmapCount;
  }

  @override
  void fillColorFromNumber(int color) {
    ui.Paint paint = ui.Paint()..color = ui.Color(color);
    this.uiCanvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), paint);
    ++_actions;
  }

  @override
  void setClip(double left, double top, double width, double height) {
    uiCanvas.clipRect(ui.Rect.fromLTWH(left, top, width, height), doAntiAlias: true);
  }

  /// Stops the recording and returns a TilePicture object.
  @override
  Future<TilePicture> finalizeBitmap() async {
    ui.Picture pic = _pictureRecorder!.endRecording();
    // unfortunately working with Picture is too slow because we have to render it each time
    ui.Image img = await pic.toImage(size.width.ceil(), size.height.ceil());
    _pictureRecorder = null;
    pic.dispose();
    TilePicture picture = FlutterTilePicture.fromBitmap(img);
    return picture;
  }

  @override
  void drawCircle(double x, double y, double radius, MapPaint paint) {
    //_log.info("draw circle at $x $y $radius $paint at ${ui.Offset(x.toDouble(), y.toDouble())}");
    uiCanvas.drawCircle(ui.Offset(x, y), radius, (paint as FlutterPaint).paint);
    ++_actions;
  }

  @override
  void drawLine(double x1, double y1, double x2, double y2, MapPaint paint) {
    //_log.info("draw line at $x1 $y1 $x2 $y2 $paint}");
    FlutterPath path = FlutterPath()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);

    drawPath(path, paint);
  }

  @override
  void drawPath(MapPath path, MapPaint paint) {
    path.drawPath(paint, uiCanvas);
    ++_pathCount;
  }

  @override
  void drawRect(MapRect rect, MapPaint paint) {
    if (paint.getStrokeDasharray() != null && paint.getStrokeDasharray()!.length >= 2) {
      FlutterPath rectPath = FlutterPath();
      rectPath.addRect(rect);
      drawPath(rectPath, paint);
    } else {
      Rect rt = (rect as FlutterRect).rect;
      uiCanvas.drawRect(rt, (paint as FlutterPaint).paint);
      ++_actions;
    }
  }

  @override
  void drawPathText(String text, LineString lineString, Mappoint reference, MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth) {
    if (text.trim().isEmpty) {
      return;
    }
    if (paint.isTransparent()) {
      return;
    }

    ParagraphEntry entry = ParagraphCache().getEntry(text, mapTextPaint, paint, maxTextWidth);

    lineString.segments.forEach((segment) {
      // So text isn't upside down
      bool doInvert = segment.end.x < segment.start.x;
      RelativeMappoint start;
      double diff = (segment.length() - entry.getWidth()) / 2;
      if (doInvert) {
        //start = segment.end.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff + entry.getWidth()).offset(-reference.x, -reference.y);
      } else {
        //start = segment.start.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff).offset(-reference.x, -reference.y);
      }
      // print(
      //     "$text: segment length ${segment.length()} - word length ${entry.getWidth()} at ${start.x - segment.start.x} / ${start.y - segment.start.y} @ ${segment.getAngle()}");
      _drawTextRotated(entry.paragraph, segment.getTheta(), start);
//      len -= segmentLength;
    });
  }

  void _drawTextRotated(ui.Paragraph paragraph, double theta, RelativeMappoint reference) {
    // since the text is rotated, use the textwidth as margin in all directions
    // if (start.x + textwidth < 0 ||
    //     start.y + textwidth < 0 ||
    //     start.x - textwidth > size.width ||
    //     start.y - textwidth > size.height) return;
    //double theta = segment.getTheta();

    // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
    uiCanvas.save();
    uiCanvas.translate(
        /*translateX +*/
        reference.x,
        /*translateY +*/ reference.y);
    uiCanvas.rotate(theta);
    uiCanvas.translate(0, -paragraph.height / 2);
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(0, 0, paragraph.longestLine, paragraph.height),
    //     ui.Paint()..color = Colors.red);
    // uiCanvas.drawCircle(Offset.zero, 10, ui.Paint()..color = Colors.green);
    uiCanvas.drawParagraph(paragraph, Offset.zero);
    uiCanvas.restore();
    ++_textCount;
  }

  /// draws the given [text] so that the center of the text in at the given x/y coordinates
  @override
  void drawText(String text, double x, double y, MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth) {
    ParagraphEntry entry = ParagraphCache().getEntry(text, mapTextPaint, paint, maxTextWidth);
    double textwidth = entry.getWidth();
    double textHeight = entry.getHeight();
    if (x + textwidth / 2 < 0 || y + entry.getHeight() < 0 || x - textwidth / 2 > size.width || y - entry.getHeight() > size.height) return;
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(x - textwidth / 2, y - textHeight / 2,
    //         entry.getWidth(), entry.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.7));
    // uiCanvas.drawCircle(ui.Offset(x - textwidth / 2, y - textHeight / 2), 10,
    //     ui.Paint()..color = Colors.green);
    uiCanvas.drawParagraph(entry.paragraph, Offset(x - textwidth / 2, y - textHeight / 2));
    // uiCanvas.drawCircle(ui.Offset(x, y), 5, ui.Paint()..color = Colors.blue);
    ++_textCount;
  }

  @override
  void scale(Offset focalPoint, double scale) {
    double diffX = size.width / 2 - focalPoint.dx;
    double diffY = size.height / 2 - focalPoint.dy;
    uiCanvas.translate((-size.width / 2 + diffX) * (scale - 1), (-size.height / 2 + diffY) * (scale - 1));
    // This method scales starting from the top/left corner. That means that the top-left corner stays at its position and the rest is scaled.
    uiCanvas.scale(scale);
  }

  @override
  void translate(double dx, double dy) {
    uiCanvas.translate(dx, dy);
  }

  @override
  String toString() {
    return 'FlutterCanvas{_actions: $_actions, _bitmapCount: $_bitmapCount, _textCount: $_textCount, _pathCount: $_pathCount}';
  }
}
