import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/tile/tile_job_queue.dart';
import 'package:mapsforge_flutter/src/tile/tile_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/utils.dart';

/// A view to display the tiles. The view updates itself whenever the [MapPosition] changes and new tiles are available.
class TileView extends StatefulWidget {
  final MapModel mapModel;

  const TileView({super.key, required this.mapModel});

  @override
  State<TileView> createState() => _TileViewState();
}

//////////////////////////////////////////////////////////////////////////////

class _TileViewState extends State<TileView> {
  late final TileJobQueue jobQueue;

  @override
  void initState() {
    super.initState();
    jobQueue = TileJobQueue(mapModel: widget.mapModel);
  }

  @override
  void dispose() {
    jobQueue.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapModel != widget.mapModel) {
      throw Exception("MapModel cannot be changed, recreate all classes which uses MapModel.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        /// Multiply the mappixels of the view with the scalefactor because the images will be shrinked by that factor in [TransformWidget].
        jobQueue.setSize(
          constraints.maxWidth * MapsforgeSettingsMgr().getDeviceScaleFactor(),
          constraints.maxHeight * MapsforgeSettingsMgr().getDeviceScaleFactor(),
        );
        // use notifier instead of stream because it should be faster
        return ListenableBuilder(
          listenable: widget.mapModel,
          builder: (BuildContext context, Widget? child) {
            MapPosition? position = widget.mapModel.lastPosition;
            if (position == null) {
              return const SizedBox();
            }
            jobQueue.setPosition(position);
            return TransformWidget(
              mapCenter: position.getCenter(),
              mapPosition: position,
              screensize: Size(constraints.maxWidth, constraints.maxHeight),
              child: child!,
            );
            //            }
            // We do not have a position yet or we wait for processing of the first tiles
            //          return const SizedBox.expand();
          },
          child: CustomPaint(foregroundPainter: TilePainter(jobQueue), child: const SizedBox.expand()),
        );
      },
    );
  }
}
