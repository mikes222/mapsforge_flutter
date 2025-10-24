import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/label/label_job_queue.dart';
import 'package:mapsforge_flutter/src/label/label_painter.dart';
import 'package:mapsforge_flutter/src/label/label_set.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/utils.dart';

/// A view to display the labels. The view updates itself whenever the [MapPosition] changes and new labels are available.
/// Labels are drawn separately so they keep orientation.
///
/// Set [minLabelZoom] to hide labels below a given zoom. If null, suppression is disabled.
class LabelView extends StatefulWidget {
  final MapModel mapModel;

  /// Hide labels when zoomlevel < minLabelZoom. Null = feature disabled.
  final int? minLabelZoom;

  const LabelView({
    super.key,
    required this.mapModel,
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
    jobQueue = LabelJobQueue(mapModel: widget.mapModel);
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

        jobQueue.setSize(
          constraints.maxWidth * scale,
          constraints.maxHeight * scale,
        );

        // If a cutoff is configured, and the last known position is below it, render nothing.
        final cutoff = widget.minLabelZoom;
        final last = widget.mapModel.lastPosition;
        if (cutoff != null && last != null && last.zoomlevel < cutoff) {
          return const SizedBox.expand();
        }

        // Optionally filter the stream when a cutoff is set.
        final Stream<LabelSet> stream = (cutoff == null)
            ? jobQueue.labelStream
            : jobQueue.labelStream.where(
                (ls) => ls.mapPosition.zoomlevel >= cutoff,
              );

        return StreamBuilder<LabelSet>(
          stream: stream,
          builder: (BuildContext context, AsyncSnapshot<LabelSet> snapshot) {
            if (snapshot.error != null) {
              return ErrorhelperWidget(
                error: snapshot.error!,
                stackTrace: snapshot.stackTrace,
              );
            }
            final data = snapshot.data;
            if (data == null) {
              // Waiting for data or suppressed by cutoff.
              return const SizedBox.expand();
            }
            return TransformWidget(
              mapCenter: data.center,
              mapPosition: data.mapPosition,
              screensize: Size(constraints.maxWidth, constraints.maxHeight),
              child: CustomPaint(
                foregroundPainter: LabelPainter(data),
                child: const SizedBox.expand(),
              ),
            );
          },
        );
      },
    );
  }
}
