import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerimpl.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/marker/userpositionmarker.dart';
import 'package:mapsforge_flutter/src/model/usercurrentposition.dart';
import 'package:mapsforge_flutter/src/service/gpsservice.dart';
import 'package:mapsforge_flutter/src/view/zoompainter.dart';

import '../../core.dart';
import '../layer/job/jobset.dart';
import 'backgroundpainter.dart';

/// Use [MapviewWidget] instead
class FlutterMapView extends StatefulWidget {
  final MapModel mapModel;
  final bool displayRealTimeLocation;
  final String? userLocationAssetIcon;
  final ViewModel viewModel;

  const FlutterMapView({
    Key? key,
    required this.mapModel,
    required this.viewModel,
    this.displayRealTimeLocation = false,
    this.userLocationAssetIcon,
  }) : super(key: key);

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
  Future<void> _initializePosition() async {
    try {
      GpsService gpsService = GpsService();
      var position = await gpsService.determinePosition();
      gpsService.startPositioning();
      widget.viewModel.updateUserLocation(UserLocation(
          latitude: position.latitude, longitude: position.longitude));
      widget.viewModel
          .setMapViewPosition(position.latitude, position.longitude);

      // Any additional initialization or state updates can go here
    } catch (e) {
      // Handle errors here
      print("Error determining position: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _jobQueue = JobQueue(
        widget.mapModel.displayModel,
        widget.mapModel.renderer,
        widget.mapModel.tileBitmapCache,
        widget.mapModel.tileBitmapCacheFirstLevel);
    _tileLayer = TileLayerImpl(displayModel: widget.mapModel.displayModel);
    if (widget.displayRealTimeLocation) {
      _initializePosition();
    }
  }

  @override
  void dispose() {
    _jobQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        widget.viewModel
            .setViewDimension(constraints.maxWidth, constraints.maxHeight);

        return SizedBox.expand(
          child: Stack(
            children: [
              StreamBuilder<MapViewPosition>(
                stream: widget.viewModel.observePosition,
                builder: (BuildContext context,
                    AsyncSnapshot<MapViewPosition> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildNoPositionView();
                  }
                  if (snapshot.hasData && snapshot.data!.hasPosition()) {
                    return _buildMapView(snapshot.data!);
                  }
                  if (widget.viewModel.mapViewPosition != null &&
                      widget.viewModel.mapViewPosition!.hasPosition()) {
                    return _buildMapView(widget.viewModel.mapViewPosition!);
                  }
                  return _buildNoPositionView();
                },
              ),
              if (widget.displayRealTimeLocation)
                _buildUserLocationMarkerStream(),
            ],
          ),
        );
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

  Widget _buildUserLocationMarkerStream() {
    return StreamBuilder<UserLocation>(
      stream: widget.viewModel.observeUserLocation,
      builder: (context, userLocationSnapshot) {
        if (userLocationSnapshot.hasData) {
          UserLocation userLocation = userLocationSnapshot.data!;
          JobSet? jobSet = _jobQueue.submitJobSet(
              widget.viewModel, widget.viewModel.mapViewPosition!, _jobQueue);
          if (jobSet == null) return const SizedBox();

          widget.mapModel.markerDataStores.add(UserPositionMarker(
              assetIcon: widget.userLocationAssetIcon!,
              symbolCache: widget.mapModel.symbolCache!,
              displayModel: widget.mapModel.displayModel,
              viewModel: widget.viewModel));
        }
        return const SizedBox();
      },
    );
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
        JobSet? jobSet = _jobQueue.submitJobSet(
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
