import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/view/view_jobqueue.dart';
import 'package:mapsforge_flutter/src/view/view_zoom_painter.dart';

import '../../core.dart';
import '../../marker.dart';
import '../utils/timing.dart';
import 'backgroundpainter.dart';
import 'errorhelper_widget.dart';

typedef Future<MapModel> CreateMapModel();

typedef Future<ViewModel> CreateViewModel();

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

typedef Widget Func();

class _MapviewWidgetState extends State<MapviewWidget> {
  static final _log = new Logger('_MapviewWidgetState');

  GlobalKey _keyView = GlobalKey();

  late ViewJobqueue _jobQueue;

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
    _jobQueue.dispose();
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
      return child();
    }

    return FutureBuilder<MapModel>(
        future: widget.createMapModel(),
        builder: (BuildContext context, AsyncSnapshot<MapModel> snapshot) {
          if (snapshot.hasError) {
            return ErrorhelperWidget(
                error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
          if (snapshot.data == null) return progress("Creating Map");
          if (snapshot.connectionState == ConnectionState.waiting)
            return progress("Waiting for Map");
          _mapModel = snapshot.data;
          _jobQueue = ViewJobqueue(
            viewRenderer: _mapModel?.renderer as ViewRenderer,
          );
          _log.info(
              "MapModel created with renderer key ${_mapModel?.renderer.getRenderKey()} in connectionState ${snapshot.connectionState.toString()}");
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
            return ErrorhelperWidget(
                error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
          if (snapshot.data == null) return progress("Creating View");
          _viewModel = snapshot.data;
          _log.info(
              "ViewModel created in connectionState ${snapshot.connectionState.toString()}");
          return child();
        });
  }

  Widget _buildView() {
    _statistics?.buildCount++;
    return _buildMapView();
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
    return _viewModel!.noPositionView;
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

  List<Widget> _createMarkerWidgets(
      ViewModel viewModel,
      MapViewPosition mapViewPosition,
      BoundingBox boundingBox,
      Mappoint mapCenter) {
    // now draw all markers
    MarkerContext markerContext = MarkerContext(
      //viewModel.viewScaleFactor,
      //viewModel,
      mapCenter,
      mapViewPosition.zoomLevel,
      mapViewPosition.projection,
      mapViewPosition.rotationRadian,
      boundingBox,
    );
    return _mapModel!.markerDataStores
        .map((datastore) => CustomPaint(
              foregroundPainter: MarkerPainter(
                dataStore: datastore,
                markerContext: markerContext,
              ),
              child: const SizedBox.expand(),
            ))
        .toList();
  }

  Widget _buildMapView() {
    //print("_buildMapView $mapViewPosition");
    Timing timing = Timing(log: _log, active: true);
    _statistics?.mapViewCount++;
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
      return Stack(
        children: [
          _buildBackgroundView() ?? const SizedBox(),
          FlutterGestureDetector(
            key: _keyView,
            viewModel: _viewModel!,
            child: const SizedBox.expand(),
            screensize: boxConstraints.biggest,
          ),
          _LayerPainter(
            viewModel: _viewModel!,
            viewJobqueue: _jobQueue,
          ),
          // StreamBuilder<MapViewPosition>(
          //     stream: _viewModel!.observePosition,
          //     builder: (BuildContext context,
          //         AsyncSnapshot<MapViewPosition> snapshot) {
          //       if (snapshot.hasError) {
          //         return ErrorhelperWidget(
          //             error: snapshot.error!, stackTrace: snapshot.stackTrace);
          //       }
          //       if (snapshot.data == null) return const SizedBox();
          //       MapViewPosition mapViewPosition = snapshot.data!;
          //       if (!mapViewPosition.hasPosition()) return const SizedBox();
          //       return Stack(
          //         children: [
          //           for (Widget widget in _createMarkerWidgets(mapViewPosition))
          //             widget,
          //           if (_viewModel!.contextMenuBuilder != null)
          //             _buildContextMenu(mapViewPosition),
          //         ],
          //       );
          //     }),
          if (_viewModel!.overlays != null)
            for (Widget widget in _viewModel!.overlays!) widget,
        ],
      );
    });
  }

  StreamBuilder<TapEvent> _buildContextMenu(MapViewPosition position) {
    return StreamBuilder<TapEvent>(
      stream: _viewModel!.observeTap,
      builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
        // _log.info(
        //     "observeTap ${snapshot.connectionState.toString()} ${snapshot.data}");
        if (snapshot.hasError) {
          return ErrorhelperWidget(
              error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
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
            Dimension(0, 0),
            // _viewModel!.mapDimension.width / _viewModel!.viewScaleFactor,
            // _viewModel!.mapDimension.height / _viewModel!.viewScaleFactor),
            event);
      },
    );
  }

  @override
  void didUpdateWidget(covariant MapviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeKey != oldWidget.changeKey) {
      //_log.info("didUpdate from ${oldWidget.changeKey} to ${widget.changeKey}");
      ViewModel? tempViewModel = _viewModel;
      MapModel? tempMapModel = _mapModel;
      _viewModel = null;
      _mapModel = null;
      Future.delayed(const Duration(milliseconds: 5000), () {
        // destroy the models AFTER they are not used anymore
        tempViewModel?.dispose();
        tempMapModel?.dispose();
      });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _LayerPainter extends StatefulWidget {
  final ViewModel viewModel;

  final ViewJobqueue viewJobqueue;

  _LayerPainter({required this.viewModel, required this.viewJobqueue});

  @override
  State<StatefulWidget> createState() {
    return _LayerState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _LayerState extends State<_LayerPainter> {
  StreamSubscription? _subscription;

  @override
  _LayerPainter get widget => super.widget;

  @override
  void initState() {
    _subscription = widget.viewModel.observePosition
        .listen((MapViewPosition mapViewPosition) {
      // unawaited(widget.viewJobqueue
      //     .getBoundaryTiles(widget.viewModel, mapViewPosition));
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: ViewZoomPainter(
        viewModel: widget.viewModel,
        viewJobqueue: widget.viewJobqueue,
      ),
      child: const SizedBox.expand(),
    );
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
