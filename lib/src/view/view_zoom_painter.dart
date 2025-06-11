import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/view/view_jobqueue.dart';

import '../../core.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/renderinfo.dart';
import '../utils/timing.dart';

/// zooms and rotates the canvas when needed before painting the map
class ViewZoomPainter extends CustomPainter {
  static final _log = new Logger('ViewZoomPainter');

  final ViewModel viewModel;

  final ViewJobqueue viewJobqueue;

  ViewZoomPainter({required this.viewModel, required this.viewJobqueue}) : super(repaint: viewJobqueue);

  /// The [size] is the size of the widget in screenpixels, take care that we
  /// often use mappixels which is off by some zoomFactors
  @override
  void paint(Canvas canvas, Size size) {
    //print("inViewZoomPainter");
    Timing timing = Timing(log: _log, active: true);
    //print("zoomPainter paint $size and position ${viewModel.mapViewPosition}");
    if (viewModel.mapViewPosition == null) return;
    RenderContext? renderContext = viewJobqueue.renderContext;
    if (renderContext == null) return;
    //print("    inViewZoomPainter ====");

    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    // flutterCanvas.setClip(
    //     0, 0, viewModel.mapDimension.width, viewModel.mapDimension.height);
    MapViewPosition mapViewPosition = viewModel.mapViewPosition!;
    // mapViewPosition.calculateBoundingBox(viewModel.mapDimension);

    if (viewModel.viewScaleFactor != 1) {
      canvas.save();
      flutterCanvas.scale(const Offset(/*viewModel.viewDimension.width / 2*/ 0, /*viewModel.viewDimension.height / 2*/ 0), 1 / viewModel.viewScaleFactor);
    }
    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      //_log.info("scaling to ${mapViewPosition.scale} around ${mapViewPosition.focalPoint}");
      canvas.save();
      flutterCanvas.scale(mapViewPosition.focalPoint!, mapViewPosition.scale);
    }

    if (mapViewPosition.rotationRadian != 0) {
      canvas.save();
      canvas.translate(size.width * viewModel.viewScaleFactor / 2, size.height * viewModel.viewScaleFactor / 2);
      canvas.rotate(mapViewPosition.rotationRadian);
      canvas.translate(-size.width * viewModel.viewScaleFactor / 2, -size.height * viewModel.viewScaleFactor / 2);
    }
    // now start drawing
    Mappoint center = mapViewPosition.getCenter();
    renderContext.drawingLayers.forEach((LayerPaintContainer layerpaintContainer) {
      //_statistics?.drawLabelCount++;
      layerpaintContainer.ways.forEach((List<RenderInfo<Shape>> renderInfos) {
        renderInfos.forEach((RenderInfo<Shape> renderInfo) {
          renderInfo.render(flutterCanvas, renderContext.projection, center, mapViewPosition.rotationRadian);
        });
      });
    });
    //_statistics?.drawLabelCount++;
    renderContext.clashDrawingLayer.ways.forEach((List<RenderInfo<Shape>> renderInfos) {
      renderInfos.forEach((RenderInfo<Shape> renderInfo) {
        renderInfo.render(flutterCanvas, renderContext.projection, center, mapViewPosition.rotationRadian);
      });
    });
    renderContext.labels.forEach((RenderInfo<Shape> renderInfo) {
      //_statistics?.drawLabelCount++;
      renderInfo.render(flutterCanvas, renderContext.projection, center, mapViewPosition.rotationRadian);
    });

    // MapPaint paint = FlutterPaint(ui.Paint());
    // MapTextPaint mapTextPaint = FlutterTextPaint()..setTextSize(30);
    // flutterCanvas.drawText("$_count", 10, 10, paint, mapTextPaint, 100);
    // flutterCanvas.drawText("$_globalCount", 120, 10, paint, mapTextPaint, 100);
    // ++_count;
    // ++_globalCount;

    // restore canvas
    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      //(canvas as FlutterCanvas).uiCanvas.drawCircle(Offset.zero, 20, Paint());
      canvas.restore();
      //(canvas as FlutterCanvas).uiCanvas.drawCircle(Offset.zero, 15, Paint()..color = Colors.amber);
    }
    if (viewModel.viewScaleFactor != 1) {
      canvas.restore();
    }

    if (mapViewPosition.rotationRadian != 0) {
      canvas.restore();
    }
    timing.done(100, "ZoomPainter done");
  }

  @override
  bool shouldRepaint(covariant ViewZoomPainter oldDelegate) {
    // print(
    //     "zoomPainter shouldRepaint ${oldDelegate.mapViewPosition != mapViewPosition}");
//    if (oldDelegate.mapViewPosition != mapViewPosition) return true;
    //if (oldDelegate.renderContext != renderContext) return true;
    return false;
  }
}
