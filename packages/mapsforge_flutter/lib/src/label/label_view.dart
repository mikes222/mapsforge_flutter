import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/label/label_job_queue.dart';
import 'package:mapsforge_flutter/src/label/label_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

/// A view to display the labels. The view updates itself whenever the [MapPosition] changes and new labels are available.
/// Labels are drawn separately so they keep orientation.
///
/// Set [minLabelZoom] to hide labels below a given zoom. If null, suppression is disabled.
class LabelView extends StatefulWidget {
  final MapModel mapModel;

  final Renderer renderer;

  /// Hide labels when zoomlevel < minLabelZoom. Null = feature disabled.
  final int? minLabelZoom;

  const LabelView({
    super.key,
    required this.mapModel,
    required this.renderer,
    this.minLabelZoom, // e.g. pass 10 to suppress under zoom 10
  });

  @override
  State<LabelView> createState() => _LabelViewState();
}

//////////////////////////////////////////////////////////////////////////////

class _LabelViewState extends State<LabelView> {
  late final LabelJobQueue jobQueue;

  @override
  void initState() {
    super.initState();
    jobQueue = LabelJobQueue(mapModel: widget.mapModel, renderer: widget.renderer);
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
        final double scale = MapsforgeSettingsMgr().getDeviceScaleFactor();

        jobQueue.setSize(constraints.maxWidth * scale, constraints.maxHeight * scale);
        // use notifier instead of stream because it should be faster
        return ListenableBuilder(
          listenable: widget.mapModel,
          builder: (BuildContext context, Widget? child) {
            MapPosition? position = widget.mapModel.lastPosition;
            if (position == null) {
              return const SizedBox();
            }
            if (widget.minLabelZoom != null && widget.minLabelZoom! >= position.zoomlevel) {
              return const SizedBox();
            }
            jobQueue.setPosition(position);
            return TransformWidget(
              mapCenter: position.getCenter(),
              mapPosition: position,
              screensize: Size(constraints.maxWidth, constraints.maxHeight),
              child: child!,
            );
          },
          child: CustomPaint(foregroundPainter: LabelPainter(jobQueue), child: const SizedBox.expand()),
        );
      },
    );
  }
}
