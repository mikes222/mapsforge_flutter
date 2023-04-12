import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerimpl.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/view/zoompainter.dart';

import '../../core.dart';
import '../layer/job/jobset.dart';
import '../utils/layerutil.dart';
import 'backgroundpainter.dart';

/// Use [MapviewWidget] instead
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
    _tileLayer = TileLayerImpl(displayModel: widget.mapModel.displayModel);
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

  List<Widget> _createMarkerWidgets(MapViewPosition mapViewPosition) {
    // now draw all markers
    return widget.mapModel.markerDataStores
        .map((datastore) => CustomPaint(
              foregroundPainter: MarkerPainter(
                mapViewPosition: mapViewPosition,
                dataStore: datastore,
                viewModel: widget.viewModel,
              ),
              child: const SizedBox.expand(),
            ))
        .toList();
  }

  Widget _buildMapView(MapViewPosition mapViewPosition) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        widget.viewModel
            .setViewDimension(constraints.maxWidth, constraints.maxHeight);
        JobSet? jobSet = LayerUtil.submitJobSet(
            widget.viewModel, mapViewPosition, _jobQueue);
        if (jobSet == null) return const SizedBox();
        return FlutterGestureDetector(
          key: _keyView,
          viewModel: widget.viewModel,
          child: Stack(
            children: [
              _buildBackgroundView() ?? const SizedBox(),
              CustomPaint(
                foregroundPainter: ZoomPainter(
                    tileLayer: _tileLayer,
                    mapViewPosition: mapViewPosition,
                    viewModel: widget.viewModel,
                    jobSet: jobSet),
                child: Container(),
              ),
              for (Widget widget in _createMarkerWidgets(mapViewPosition))
                widget,
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
                            mapViewPosition,
                            Dimension(
                                widget.viewModel.mapDimension.width /
                                    widget.viewModel.viewScaleFactor,
                                widget.viewModel.mapDimension.height /
                                    widget.viewModel.viewScaleFactor),
                            event);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
