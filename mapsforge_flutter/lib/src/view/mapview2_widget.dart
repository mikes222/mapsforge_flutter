import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerlabel.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/view/view_jobqueue.dart';
import 'package:mapsforge_flutter/src/view/view_zoom_painter.dart';

import '../../core.dart';
import '../layer/tilelayer.dart';
import '../rendertheme/rendercontext.dart';
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
class Mapview2Widget extends StatefulWidget {
  final DisplayModel displayModel;

  final CreateMapModel createMapModel;

  final CreateViewModel createViewModel;

  /// A key to recognize changes. If for example the rendering should change also change that key.
  /// Suggestion is to use [renderer.getRenderKey()] for this value. If the key changes the whole
  /// view will be rebuilt and the MapModel and ViewModel will be asked to recreate.
  final String? changeKey;

  const Mapview2Widget({
    Key? key,
    required this.displayModel,
    required this.createMapModel,
    required this.createViewModel,
    this.changeKey,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _Mapview2WidgetState();
  }
}

/////////////////////////////////////////////////////////////////////////////

typedef Widget Func();

class _Mapview2WidgetState extends State<Mapview2Widget> {
  static final _log = new Logger('_MapviewWidgetState');

  TileLayer? _labelLayer;

  GlobalKey _keyView = GlobalKey();

  ViewJobqueue? _jobQueue;

  MapModel? _mapModel;

  ViewModel? _viewModel;

  StreamSubscription<MapViewPosition>? _subscription;

  _Statistics? _statistics; // = _Statistics();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _viewModel?.dispose();
    _labelLayer?.dispose();
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
            return ErrorhelperWidget(
                error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
          if (snapshot.data == null) return progress("Creating Map");
          if (snapshot.connectionState == ConnectionState.waiting)
            return progress("Waiting for Map");
          _mapModel = snapshot.data;
          _jobQueue = ViewJobqueue(
            tileSize: widget.displayModel.tileSize,
            viewRenderer: _mapModel?.renderer as ViewRenderer,
          );
          _labelLayer = TileLayerLabel();
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
          _subscription = _viewModel!.observePosition
              .listen((MapViewPosition mapViewPosition) async {
            //print("MapView2Widget: new Position");
            unawaited(
                _jobQueue!.getBoundaryTiles(_viewModel!, mapViewPosition));
          });
          return child();
        });
  }

  Widget _buildView() {
    _statistics?.buildCount++;
    return LayoutBuilder(builder: (context, BoxConstraints boxConstraints) {
      _viewModel!
          .setViewDimension(boxConstraints.maxWidth, boxConstraints.maxHeight);
      return _buildMapView();
    });
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

  List<Widget> _createMarkerWidgets(MapViewPosition mapViewPosition) {
    // now draw all markers
    return _mapModel!.markerDataStores
        .map((datastore) => CustomPaint(
              foregroundPainter: MarkerPainter(
                mapViewPosition: mapViewPosition,
                dataStore: datastore,
                viewModel: _viewModel!,
              ),
              child: const SizedBox.expand(),
            ))
        .toList();
  }

  Widget _buildMapView() {
    //print("_buildMapView $mapViewPosition");
    _statistics?.mapViewCount++;
    return Stack(
      children: [
        _buildBackgroundView() ?? const SizedBox(),
        FlutterGestureDetector(
            key: _keyView,
            viewModel: _viewModel!,
            child: const SizedBox.expand()),
        _LayerPainter(
          viewModel: _viewModel!,
          viewJobqueue: _jobQueue!,
        ),
        // StreamBuilder<RenderContext>(
        //     stream: _jobQueue!.observeRenderContext,
        //     builder:
        //         (BuildContext context, AsyncSnapshot<RenderContext> snapshot) {
        //       print("new Frame");
        //       if (snapshot.hasError) {
        //         return ErrorhelperWidget(
        //             error: snapshot.error!, stackTrace: snapshot.stackTrace);
        //       }
        //       if (snapshot.data == null) return _buildNoPositionView();
        //       return;
        //     }),
        // if (_viewModel!.overlays != null)
        //   for (Widget widget in _viewModel!.overlays!) widget,
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
        //       return Stack(
        //         children: [
        //           for (Widget widget in _createMarkerWidgets(mapViewPosition))
        //             widget,
        //           if (_viewModel!.contextMenuBuilder != null)
        //             _buildContextMenu(mapViewPosition),
        //         ],
        //       );
        //     }),
      ],
    );
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
            Dimension(
                _viewModel!.mapDimension.width / _viewModel!.viewScaleFactor,
                _viewModel!.mapDimension.height / _viewModel!.viewScaleFactor),
            event);
      },
    );
  }

  @override
  void didUpdateWidget(covariant Mapview2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeKey != oldWidget.changeKey) {
      //_log.info("didUpdate from ${oldWidget.changeKey} to ${widget.changeKey}");
      ViewModel? tempViewModel = _viewModel;
      ViewJobqueue? tempJobqueue = _jobQueue;
      MapModel? tempMapModel = _mapModel;
      _viewModel = null;
      _jobQueue = null;
      _labelLayer = null;
      _mapModel = null;
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
  StreamSubscription<RenderContext>? _subscription;

  RenderContext? _renderContext;

  int _count = 0;

  static int _globalCount = 0;

  @override
  void initState() {
    _subscription = widget.viewJobqueue.observeRenderContext
        .listen((RenderContext renderContext) async {
      setState(() {
        //print("_LayerState: rendercontext");
        _renderContext = renderContext;
      });
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
    if (_renderContext == null) return const SizedBox();
    ++_count;
    ++_globalCount;
    //return Text("$_count $_globalCount");
    return CustomPaint(
      foregroundPainter: ViewZoomPainter(
        viewModel: widget.viewModel,
        renderContext: _renderContext!,
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
