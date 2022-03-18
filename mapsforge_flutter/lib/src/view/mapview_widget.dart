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

typedef Future<MapModel> CreateMapModel();
typedef Future<ViewModel> CreateViewModel();

/// A Widget which provides the map. The widget asks for MapModel and ViewModel when
/// needed and also destroys the models when not needed anymore.
class MapviewWidget extends StatefulWidget {
  final DisplayModel displayModel;

  final CreateMapModel createMapModel;

  final CreateViewModel createViewModel;

  /// A key to recognize changes. If for example the rendering should change also change that key.
  /// Suggestion is to use [renderer.getRenderKey()] for this value. If the key changes the whole
  /// view will be rebuilt and the MapModel and ViewModel will be asked to recreate.
  final String? changeKey;

  const MapviewWidget({
    Key? key,
    required this.displayModel,
    required this.createMapModel,
    required this.createViewModel,
    this.changeKey,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MapviewWidgetState();
  }
}

/////////////////////////////////////////////////////////////////////////////

typedef Widget Func();

class _MapviewWidgetState extends State<MapviewWidget> {
  static final _log = new Logger('_MapviewWidgetState');

  TileLayerImpl? _tileLayer;

  GlobalKey _keyView = GlobalKey();

  JobQueue? _jobQueue;

  MapModel? _mapModel;

  ViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    //_tileLayer.dis
    _jobQueue?.dispose();
    _mapModel?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _createMapModel(() => _createViewModel(() => _buildView()));
  }

  Widget _createMapModel(Func child) {
    if (_mapModel != null) {
      assert(_jobQueue != null);
      assert(_tileLayer != null);
      return child();
    }

    return FutureBuilder<MapModel>(
        future: widget.createMapModel(),
        builder: (BuildContext context, AsyncSnapshot<MapModel> snapshot) {
          if (snapshot.hasError) {
            return Text(
                snapshot.error?.toString() ?? "Error while creating map",
                style: const TextStyle(color: Colors.red));
          }
          if (snapshot.data == null) return progress("Creating Map");
          if (snapshot.connectionState == ConnectionState.waiting)
            return progress("Waiting for Map");
          _mapModel = snapshot.data;
          _jobQueue = JobQueue(
            widget.displayModel,
            _mapModel!.renderer,
            _mapModel!.tileBitmapCache,
            _mapModel!.tileBitmapCacheFirstLevel,
          );
          _tileLayer = TileLayerImpl(
            displayModel: widget.displayModel,
            jobQueue: _jobQueue!,
          );
          _log.info(
              "MapModel created ${_mapModel?.renderer.getRenderKey()}  ${snapshot.connectionState.toString()}");
          return child();
        });
  }

  Widget _createViewModel(Func child) {
    if (_viewModel != null) return child();
    return FutureBuilder<ViewModel>(
        future: widget.createViewModel(),
        builder: (BuildContext context, AsyncSnapshot<ViewModel> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return progress("Waiting for View");
          if (snapshot.hasError) {
            return Text(
                snapshot.error?.toString() ?? "Error while creating view",
                style: const TextStyle(color: Colors.red));
          }
          if (snapshot.data == null) return progress("Creating View");
          _viewModel = snapshot.data;
          _log.info("ViewModel created ${snapshot.connectionState.toString()}");
          return child();
        });
  }

  Widget _buildView() {
    return FlutterGestureDetector(
        key: _keyView,
        viewModel: _viewModel!,
        child: StreamBuilder<MapViewPosition?>(
          stream: _viewModel!.observePosition,
          builder:
              (BuildContext context, AsyncSnapshot<MapViewPosition?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return _buildNoPositionView();
            if (snapshot.hasData) {
              if (snapshot.data!.hasPosition()) {
                //_log.info("I have a new position ${snapshot.data.toString()}");
                return _buildMapView(snapshot.data!);
              }
              //return _buildNoPositionView();
            }
            if (_viewModel!.mapViewPosition != null &&
                _viewModel!.mapViewPosition!.hasPosition()) {
              //_log.info(
              //    "I have an old position ${widget.viewModel.mapViewPosition!.toString()}");
              return _buildMapView(_viewModel!.mapViewPosition!);
            }
            return _buildNoPositionView();
          },
        ));
  }

  @protected
  Widget progress(String text) {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildNoPositionView() {
    return _viewModel!.noPositionView!;
  }

  Widget? _buildBackgroundView() {
    if (_viewModel!.displayModel.backgroundColor != Colors.transparent.value) {
      // draw the background first
      return CustomPaint(
        foregroundPainter: BackgroundPainter(displayModel: widget.displayModel),
        child: Container(),
      );
    }
    return null;
  }

  List<Widget> _createMarkerWidgets(MapViewPosition position) {
    List<Widget> markerWidgets = [];

    // now draw all markers
    markerWidgets.addAll(_mapModel!.markerDataStores
        .map((IMarkerDataStore markerDataStore) => CustomPaint(
              foregroundPainter: MarkerPainter(
                  position: position,
                  displayModel: _mapModel!.displayModel,
                  dataStore: markerDataStore,
                  viewModel: _viewModel!),
              child: Container(),
            ))
        .toList());
    return markerWidgets;
  }

  Widget _buildMapView(MapViewPosition position) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _viewModel!
            .setViewDimension(constraints.maxWidth, constraints.maxHeight);
        JobSet? jobSet = _submitJobSet(_viewModel!, position, _jobQueue!);
//        _log.info("JobSet is $jobSet");
        return Stack(
          children: [
            _buildBackgroundView() ?? const SizedBox(),
            if (jobSet != null)
              CustomPaint(
                foregroundPainter: TileLayerPainter(
                    _tileLayer!, position, _viewModel!, jobSet),
                child: Container(),
              ),
            for (Widget widget in _createMarkerWidgets(position)) widget,
            if (_viewModel!.overlays != null)
              for (Widget widget in _viewModel!.overlays!) widget,
            if (_viewModel!.contextMenuBuilder != null)
              StreamBuilder<TapEvent>(
                stream: _viewModel!.observeTap,
                builder:
                    (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
                  // _log.info(
                  //     "observeTap ${snapshot.connectionState.toString()} ${snapshot.data}");
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SizedBox();
                  if (!snapshot.hasData) return const SizedBox();
                  TapEvent event = snapshot.data!;
                  if (event.isCleared()) return const SizedBox();
                  // with every position-update this context menu is called after the first tap-event
                  return _viewModel!.contextMenuBuilder!.buildContextMenu(
                      context,
                      _mapModel!,
                      _viewModel!,
                      position,
                      _viewModel!.viewDimension!,
                      event);
                },
              ),
          ],
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

  @override
  void didUpdateWidget(covariant MapviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeKey != oldWidget.changeKey) {
      //_log.info("didUpdate from ${oldWidget.changeKey} to ${widget.changeKey}");
      ViewModel? tempViewModel = _viewModel;
      JobQueue? tempJobqueue = _jobQueue;
      MapModel? tempMapModel = _mapModel;
      _viewModel = null;
      _jobQueue = null;
      _tileLayer = null;
      _mapModel = null;
      Future.delayed(const Duration(milliseconds: 5000), () {
        // destroy the models ATER they are not used anymore
        tempViewModel?.dispose();
        tempJobqueue?.dispose();
        tempMapModel?.dispose();
      });
    }
  }
}
