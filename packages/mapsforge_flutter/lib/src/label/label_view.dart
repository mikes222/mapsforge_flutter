import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/label/label_job_queue.dart';
import 'package:mapsforge_flutter/src/label/label_painter.dart';
import 'package:mapsforge_flutter/src/label/label_set.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/utils.dart';

/// A view to display the labels. The view updates itself whenever the [MapPosition] changes and new labels are available. This only works if
/// the renderer supports labels. The labels will NOT be rendered into the tiles but instead drawn separately so that the labels are always
/// facing in the same orientation.
class LabelView extends StatefulWidget {
  final MapModel mapModel;

  LabelView({super.key, required this.mapModel});

  @override
  State<LabelView> createState() => _LabelViewState();
}

//////////////////////////////////////////////////////////////////////////////

class _LabelViewState extends State<LabelView> {
  late final LabelJobQueue jobQueue;

  @override
  void initState() {
    super.initState();
    jobQueue = LabelJobQueue(mapsforgeModel: widget.mapModel);
  }

  @override
  void dispose() {
    jobQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        /// Multiply the mappixels of the view with the scalefactor because the images will be shrinked by that factor while drawing them.
        jobQueue.setSize(
          constraints.maxWidth * MapsforgeSettingsMgr().getDeviceScaleFactor(),
          constraints.maxHeight * MapsforgeSettingsMgr().getDeviceScaleFactor(),
        );
        return StreamBuilder(
          stream: jobQueue.labelStream,
          builder: (BuildContext context, AsyncSnapshot<LabelSet> snapshot) {
            if (snapshot.error != null) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            if (snapshot.data != null) {
              return TransformWidget(
                mapCenter: snapshot.data!.center,
                mapPosition: snapshot.data!.mapPosition,
                screensize: Size(constraints.maxWidth, constraints.maxHeight),
                child: CustomPaint(foregroundPainter: LabelPainter(snapshot.data!), child: const SizedBox.expand()),
              );
            }
            // TileView shows already a circular progress indicator, do not do it twice
            return const SizedBox.expand();
          },
        );
      },
    );
  }
}
