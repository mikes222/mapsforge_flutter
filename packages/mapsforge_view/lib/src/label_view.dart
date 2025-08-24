import 'package:dart_common/utils.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/label_job_queue.dart';
import 'package:mapsforge_view/src/label_painter.dart';
import 'package:mapsforge_view/src/label_set.dart';
import 'package:mapsforge_view/src/transform_widget.dart';

/// A view to display the tiles. The view updates itself whenever the [MapPosition] changes and new tiles are available.
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
              print(snapshot.error);
              print(snapshot.stackTrace);
              return Text("${snapshot.error}", style: TextStyle(color: Theme.of(context).colorScheme.error));
            }
            if (snapshot.data != null) {
              return TransformWidget(
                mapCenter: snapshot.data!.center,
                mapPosition: snapshot.data!.mapPosition,
                screensize: Size(constraints.maxWidth, constraints.maxHeight),
                child: CustomPaint(foregroundPainter: LabelPainter(snapshot.data!), child: const SizedBox.expand()),
              );
            }
            return const Placeholder();
          },
        );
      },
    );
  }
}
