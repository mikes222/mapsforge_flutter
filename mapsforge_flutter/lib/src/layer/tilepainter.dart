import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/renderer/rendererjob.dart';

import '../../core.dart';
import '../../maps.dart';
import 'job/job.dart';
import 'job/jobqueue.dart';

class TilePainter extends ChangeNotifier implements CustomPainter {
  final Tile tile;

  final JobQueue jobQueue;

  final JobRenderer jobRenderer;

  final MapPaint _paint;

  bool _needsRepaint = true;

  TilePainter({
    this.tile,
    this.jobQueue,
    this.jobRenderer,
    @required GraphicFactory graphicFactory,
  })  : assert(tile != null),
        assert(jobQueue != null),
        assert(jobRenderer != null),
        _paint = graphicFactory.createPaint();

  @override
  bool hitTest(Offset position) {
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Job job = jobQueue.createJob(tile);
    List<RendererJob> jobs = List();
    jobs.add(job);
    this.jobQueue.addJobs(jobs);

    TileBitmap bitmap = jobRenderer.getMissingBitmap(tile);
    if (bitmap != null) {
      FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
      flutterCanvas.drawBitmap(
        bitmap: bitmap,
        left: 0,
        top: 0,
        paint: _paint,
      ); //, (point.x), (point.y), this.displayModel.getFilter());
    }
  }

  @override
  get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    return false;
  }

  @override
  bool shouldRepaint(TilePainter oldDelegate) {
//    if (oldDelegate?.position != position) return true;
    if (_needsRepaint) return true;
    return false;
  }
}
