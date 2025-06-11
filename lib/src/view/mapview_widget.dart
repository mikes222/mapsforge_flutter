import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/view/tile_painter.dart';
import 'package:mapsforge_flutter/src/view/transform_widget.dart';

import '../../core.dart';
import '../layer/job/jobset.dart';
import 'backgroundpainter.dart';
import 'errorhelper_widget.dart';
import 'label_painter.dart';
import 'mapview2_widget.dart';

/// A Widget which provides the map. The widget asks for MapModel and ViewModel when
/// needed and also destroys the models when not needed anymore. You cannot
/// directly access the viewmodel and mapmodel to avoid access-problems after
/// the lifecycle of the objects is due. Suggested method to access the objects
/// is by attaching
/// an Overlay to the viewModel. See [ZoomOverlay] for an example.
class MapviewWidget extends StatefulWidget {
  final DisplayModel displayModel;

  final CreateMapModel createMapModel;

  final CreateViewModel createViewModel;

  /// A key to recognize changes. If for example the rendering should change also change that key.
  /// Suggestion is to use renderer.getRenderKey() for this value. If the key changes the whole
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

class _MapviewWidgetState extends State<MapviewWidget> {
  static final _log = new Logger('_MapviewWidgetState');

  GlobalKey _keyView = GlobalKey();

  final GlobalKey myKey = GlobalKey();

  JobQueue? _jobQueue;

  MapModel? _mapModel;

  ViewModel? _viewModel;

  _Statistics? _statistics; // = _Statistics();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    _jobQueue?.dispose();
    _mapModel?.dispose();
    //_jobSet?.dispose();

    super.dispose();
    if (_statistics != null) _log.info(_statistics?.toString());
  }

  @override
  Widget build(BuildContext context) {
    return _createMapModel(() => _createViewModel(() => _buildView()));
  }

  Widget _createMapModel(Func child) {
    if (_mapModel != null) {
      assert(_jobQueue != null);
      return child();
    }

    return FutureBuilder<MapModel>(
        future: widget.createMapModel(),
        builder: (BuildContext context, AsyncSnapshot<MapModel> snapshot) {
          if (snapshot.hasError) {
            _log.warning(snapshot.stackTrace);
            return Text("Error while creating map: ${snapshot.error?.toString()}", style: const TextStyle(color: Colors.red));
          }
          if (snapshot.data == null) return progress("Creating Map");
          if (snapshot.connectionState == ConnectionState.waiting) return progress("Waiting for Map");
          _mapModel = snapshot.data;
          _jobQueue = JobQueue(
            _mapModel!.renderer,
            _mapModel!.tileBitmapCache,
            _mapModel!.tileBitmapCacheFirstLevel,
            _mapModel!.parallelJobs,
          );
          _log.info("MapModel created with renderer key ${_mapModel?.renderer.getRenderKey()} in connectionState ${snapshot.connectionState.toString()}");
          return child();
        });
  }

  Widget _createViewModel(Func child) {
    if (_viewModel != null) return child();
    return FutureBuilder<ViewModel>(
        future: widget.createViewModel(),
        builder: (BuildContext context, AsyncSnapshot<ViewModel> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return progress("Waiting for View");
          if (snapshot.hasError) {
            _log.warning(snapshot.stackTrace);
            return Text("Error while creating view: ${snapshot.error?.toString()}", style: const TextStyle(color: Colors.red));
          }
          if (snapshot.data == null) return progress("Creating View");
          _viewModel = snapshot.data;
          _log.info("ViewModel created in connectionState ${snapshot.connectionState.toString()}");
          return child();
        });
  }

  Widget _buildView() {
    _statistics?.buildCount++;
    if ((_viewModel?.mapViewPosition?.hasPosition() ?? false) == false) {
      return StreamBuilder(
          stream: _viewModel!.observePosition,
          builder: (context, AsyncSnapshot<MapViewPosition> snapshot) {
            if (snapshot.hasError) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            if (snapshot.data?.hasPosition() ?? false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {});
              });
            }
            return _viewModel?.noPositionView ??
                const Center(
                  child: CircularProgressIndicator(),
                );
          });
    }
    return _buildMapView();
  }

  @protected
  Widget progress(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(text),
        ],
      ),
    );
  }

  Widget? _buildBackgroundView() {
    _statistics?.buildBackgroundCount++;
    if (_viewModel!.displayModel.backgroundColor != Colors.transparent.value) {
      // draw the background first
      return CustomPaint(
        foregroundPainter: BackgroundPainter(displayModel: widget.displayModel),
        child: const SizedBox.expand(),
      );
    }
    return null;
  }

  Widget _buildMapView() {
    _statistics?.mapViewCount++;
    return SafeArea(
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints boxConstraints) {
        return Stack(
          key: myKey,
          children: [
            _buildBackgroundView() ?? const SizedBox(),
            FlutterGestureDetector(
              key: _keyView,
              viewModel: _viewModel!,
              child: const SizedBox.expand(),
              screensize: boxConstraints.biggest,
            ),
            _TileWidget(
              mapModel: _mapModel!,
              viewModel: _viewModel!,
              jobQueue: _jobQueue!,
              screensize: boxConstraints.biggest,
            ),
            if (_viewModel?.contextMenuBuilder != null) _buildContextMenu(boxConstraints.biggest, _viewModel!.contextMenuBuilder!),
            if (_viewModel!.overlays != null)
              for (Widget widget in _viewModel!.overlays!) widget,
          ],
        );
      }),
    );
  }

  StreamBuilder<TapEvent> _buildContextMenu(Size screensize, ContextMenuBuilder contextMenuBuilder) {
    return StreamBuilder<TapEvent>(
      stream: _viewModel!.observeTap,
      builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
        // _log.info(
        //     "observeTap ${snapshot.connectionState.toString()} ${snapshot.data}");
        if (snapshot.hasError) {
          return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        if (!snapshot.hasData) return const SizedBox();
        TapEvent event = snapshot.data!;
        if (event.isCleared()) return const SizedBox();
        // with every position-update this context menu is called after the first tap-event
        return StreamBuilder<MapViewPosition>(
            stream: _viewModel!.observePosition,
            builder: (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
              if (snapshot.hasError) {
                return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
              }
              if (snapshot.data == null) return const SizedBox();
              MapViewPosition mapViewPosition = snapshot.data!;
              return contextMenuBuilder.buildContextMenu(
                  context, _mapModel!, _viewModel!, mapViewPosition, Dimension(screensize.width, screensize.height), event);
            });
      },
    );
  }

  @override
  void didUpdateWidget(covariant MapviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeKey != oldWidget.changeKey) {
      //_log.info("didUpdate from ${oldWidget.changeKey} to ${widget.changeKey}");
      ViewModel? tempViewModel = _viewModel;
      JobQueue? tempJobqueue = _jobQueue;
      MapModel? tempMapModel = _mapModel;
      if (mounted) {
        setState(() {
          _viewModel = null;
          _jobQueue = null;
          _mapModel = null;
        });
      }
      Future.delayed(const Duration(milliseconds: 5000), () {
        // destroy the models AFTER they are not used anymore
        tempViewModel?.dispose();
        tempJobqueue?.dispose();
        tempMapModel?.dispose();
      });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _TileWidget extends StatelessWidget {
  final MapModel mapModel;

  final ViewModel viewModel;

  final JobQueue jobQueue;

  final Size screensize;

  _TileWidget({
    required this.mapModel,
    required this.viewModel,
    required this.jobQueue,
    required this.screensize,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapViewPosition>(
        stream: viewModel.observePosition,
        builder: (context, AsyncSnapshot<MapViewPosition> snapshot) {
          if (snapshot.hasError) {
            return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
          if (snapshot.data == null) return const SizedBox();
          MapViewPosition mapViewPosition = snapshot.data!;
          if (!mapViewPosition.hasPosition()) return const SizedBox();
          JobSet? jobSet = jobQueue.createJobSet(
              viewModel, mapViewPosition, MapSize(width: screensize.width * viewModel.viewScaleFactor, height: screensize.height * viewModel.viewScaleFactor));
          if (jobSet == null) return const SizedBox();
          // print(
          //     "${jobSet.indoorLevel} ${jobSet.renderJobs.firstOrNull?.tile.indoorLevel}");
          return TransformWidget(
            viewModel: viewModel,
            mapViewPosition: mapViewPosition,
            screensize: screensize,
            mapCenter: jobSet.getCenter(),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    foregroundPainter: TilePainter(viewModel: viewModel, jobSet: jobSet),
                    size: screensize,
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    foregroundPainter: LabelPainter(viewModel: viewModel, jobSet: jobSet, rotationRadian: mapViewPosition.rotationRadian),
                    size: screensize,
                  ),
                ),
                // RepaintBoundary(
                //   child: CustomPaint(
                //     foregroundPainter: DebugPainter(viewModel: viewModel),
                //     size: screensize,
                //   ),
                // ),
                for (Widget widget in _createMarkerWidgets(mapViewPosition, jobSet.boundingBox, jobSet.getCenter())) widget,
              ],
            ),
          );
        });
  }

  List<Widget> _createMarkerWidgets(MapViewPosition mapViewPosition, BoundingBox boundingBox, Mappoint mapCenter) {
    MarkerContext markerContext = MarkerContext(
      mapCenter,
      mapViewPosition.zoomLevel,
      mapViewPosition.projection,
      mapViewPosition.rotationRadian,
      boundingBox,
    );
    // now draw all markers
    return mapModel.markerDataStores
        .map((datastore) => RepaintBoundary(
              child: CustomPaint(
                foregroundPainter: MarkerPainter(
                  dataStore: datastore,
                  markerContext: markerContext,
                ),
                child: const SizedBox.expand(),
              ),
            ))
        .toList();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _Statistics {
  int buildCount = 0;

  int buildBackgroundCount = 0;

  int positionChangeCount = 0;

  int mapViewCount = 0;

  @override
  String toString() {
    return '_Statistics{buildCount: $buildCount, buildBackgroundCount: $buildBackgroundCount, positionChangeCount: $positionChangeCount, mapViewCount: $mapViewCount}';
  }
}
