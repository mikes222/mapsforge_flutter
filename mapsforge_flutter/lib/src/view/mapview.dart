import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerimpl.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';

import '../../core.dart';
import 'backgroundpainter.dart';
import 'tilelayerpainter.dart';

class FlutterMapView extends StatefulWidget {
  final MapModel mapModel;

  final ViewModel viewModel;

  const FlutterMapView(
      {Key? key, required this.mapModel, required this.viewModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FlutterMapState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _FlutterMapState extends State<FlutterMapView> {
  static final _log = new Logger('_FlutterMapState');

  late TileLayerImpl _tileLayer;

  GlobalKey _keyView = GlobalKey();

  late JobQueue _jobQueue;

  @override
  void initState() {
    super.initState();
    _jobQueue = JobQueue(
        widget.mapModel.displayModel,
        widget.mapModel.renderer,
        widget.mapModel.tileBitmapCache,
        widget.mapModel.tileBitmapCacheFirstLevel);
    _tileLayer = TileLayerImpl(
      displayModel: widget.mapModel.displayModel,
      jobQueue: _jobQueue,
    );
  }

  @override
  void dispose() {
    _jobQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapViewPosition>(
      stream: widget.viewModel.observePosition,
      builder: (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
        //print("position ${snapshot.connectionState} with ${snapshot.data}");
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildNoPositionView();
        if (snapshot.hasData) {
          if (snapshot.data!.hasPosition()) {
            //_log.info("I have a new position ${snapshot.data.toString()}");
            return _buildMapView(snapshot.data!);
          }
          //return _buildNoPositionView();
        }
        if (widget.viewModel.mapViewPosition != null &&
            widget.viewModel.mapViewPosition!.hasPosition()) {
          //_log.info(
          //    "I have an old position ${widget.viewModel.mapViewPosition!.toString()}");
          return _buildMapView(widget.viewModel.mapViewPosition!);
        }
        return _buildNoPositionView();
      },
    );
  }

  Widget _buildNoPositionView() {
    return widget.viewModel.noPositionView!;
  }

  Widget? _buildBackgroundView() {
    if (widget.mapModel.displayModel.backgroundColor !=
        Colors.transparent.value) {
      // draw the background first
      return CustomPaint(
        foregroundPainter:
            BackgroundPainter(displayModel: widget.mapModel.displayModel),
        child: Container(),
      );
    }
    return null;
  }

  Widget _buildMapView(MapViewPosition position) {
    List<Widget> markerWidgets = [];

    // now draw all markers
    markerWidgets.addAll(widget.mapModel.markerDataStores
        .map((IMarkerDataStore markerDataStore) => CustomPaint(
              foregroundPainter: MarkerPainter(
                  position: position,
                  displayModel: widget.mapModel.displayModel,
                  dataStore: markerDataStore,
                  viewModel: widget.viewModel,
                  symbolCache: widget.mapModel.symbolCache),
              child: Container(),
            ))
        .toList());

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        widget.viewModel
            .setViewDimension(constraints.maxWidth, constraints.maxHeight);
        JobSet? jobSet = _submitJobSet(widget.viewModel, position, _jobQueue);
//        _log.info("JobSet is $jobSet");
        return FlutterGestureDetector(
          key: _keyView,
          viewModel: widget.viewModel,
          child: Stack(
            children: [
              _buildBackgroundView() ?? const SizedBox(),
              if (jobSet != null)
                CustomPaint(
                  foregroundPainter: TileLayerPainter(
                      _tileLayer, position, widget.viewModel, jobSet),
                  child: Container(),
                ),
              for (Widget widget in markerWidgets) widget,
              if (widget.viewModel.overlays != null)
                for (Widget widget in widget.viewModel.overlays!) widget,
              if (widget.viewModel.contextMenuBuilder != null)
                StreamBuilder<TapEvent>(
                  stream: widget.viewModel.observeTap,
                  builder:
                      (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const SizedBox();
                    if (!snapshot.hasData) return const SizedBox();
                    TapEvent event = snapshot.data!;
                    if (event.isCleared()) return const SizedBox();
                    return widget.viewModel.contextMenuBuilder!
                        .buildContextMenu(
                            context,
                            widget.mapModel,
                            widget.viewModel,
                            position,
                            widget.viewModel.viewDimension!,
                            event);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  JobSet? _submitJobSet(
      ViewModel viewModel, MapViewPosition mapViewPosition, JobQueue jobQueue) {
    //_log.info("viewModel ${viewModel.viewDimension}");
    if (viewModel.viewDimension == null) return null;
    int time = DateTime.now().millisecondsSinceEpoch;
    List<Tile> tiles = LayerUtil.getTiles(viewModel, mapViewPosition, time);
    JobSet jobSet = JobSet();
    tiles.forEach((Tile tile) {
      Job job = Job(tile, false, viewModel.displayModel.getUserScaleFactor(),
          viewModel.displayModel.tileSize);
      jobSet.add(job);
    });
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50)
      _log.info("diff: $diff ms, ${jobSet.jobs.length} missing tiles");
    //_log.info("JobSets created: ${jobSet.jobs.length}");
    if (jobSet.jobs.length > 0) {
      jobQueue.processJobset(jobSet);
      return jobSet;
    }
    return null;
  }
}
