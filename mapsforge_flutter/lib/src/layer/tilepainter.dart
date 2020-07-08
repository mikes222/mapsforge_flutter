import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';

import '../../core.dart';
import '../../maps.dart';
import 'job/jobqueue.dart';

///
/// Originally used by mapsforge to paint one tile. This is not suitable in flutter so this class is not used
abstract class TilePainter extends ChangeNotifier implements CustomPainter {
  final JobQueue jobQueue;

  final JobRenderer jobRenderer;

  final MapPaint _paint;

  bool _needsRepaint = true;

  TilePainter({
    this.jobQueue,
    this.jobRenderer,
    @required GraphicFactory graphicFactory,
  })  : assert(jobQueue != null),
        assert(jobRenderer != null),
        _paint = graphicFactory.createPaint();

  @override
  bool hitTest(Offset position) {
    return null;
  }

  @override
  void paint(Canvas canvas, Size size);

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
