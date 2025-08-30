import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/tile/tile_job_queue.dart';
import 'package:mapsforge_view/src/tile/tile_painter.dart';
import 'package:mapsforge_view/src/tile/tile_set.dart';
import 'package:mapsforge_view/src/transform_widget.dart';

/// A view to display the tiles. The view updates itself whenever the [MapPosition] changes and new tiles are available.
class TileView extends StatefulWidget {
  final MapModel mapModel;

  TileView({super.key, required this.mapModel});

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
        return StreamBuilder(
          stream: jobQueue.tileStream,
          builder: (BuildContext context, AsyncSnapshot<TileSet> snapshot) {
            if (snapshot.error != null) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            if (snapshot.data != null) {
              return TransformWidget(
                mapCenter: snapshot.data!.center,
                mapPosition: snapshot.data!.mapPosition,
                screensize: Size(constraints.maxWidth, constraints.maxHeight),
                child: CustomPaint(foregroundPainter: TilePainter(snapshot.data!), child: const SizedBox.expand()),
              );
            }
            // We do not have a position yet or we wait for processing of the first tiles
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}
