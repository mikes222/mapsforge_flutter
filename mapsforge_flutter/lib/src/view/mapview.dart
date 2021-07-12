import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobqueue.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerimpl.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';
import 'package:mapsforge_flutter/src/marker/markerpainter.dart';
import 'package:mapsforge_flutter/src/marker/markerrenderer.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:provider/provider.dart';

import '../../core.dart';
import 'backgroundpainter.dart';
import 'contextmenu.dart';
import 'tilelayerpainter.dart';

class FlutterMapView extends StatefulWidget {
  final MapModel mapModel;

  final ViewModel viewModel;

  final GraphicFactory graphicFactory;

  const FlutterMapView(
      {Key? key,
      required this.mapModel,
      required this.viewModel,
      required this.graphicFactory})
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

  List<MarkerRenderer> _markerRenderer = [];

  GlobalKey _keyView = GlobalKey();

  late JobQueue _jobQueue;

  @override
  void initState() {
    super.initState();
    _jobQueue = JobQueue(widget.mapModel.displayModel, widget.mapModel.renderer,
        widget.mapModel.tileBitmapCache);
    _tileLayer = TileLayerImpl(
      displayModel: widget.mapModel.displayModel,
      graphicFactory: widget.graphicFactory,
      jobQueue: _jobQueue,
    );
    widget.mapModel.markerDataStores.forEach((MarkerDataStore dataStore) {
      MarkerRenderer markerRenderer =
          MarkerRenderer(widget.graphicFactory, widget.viewModel, dataStore);
      _markerRenderer.add(markerRenderer);
    });
  }

  @override
  void dispose() {
    _jobQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapViewPosition?>(
      stream: widget.viewModel.observePosition,
      builder:
          (BuildContext context, AsyncSnapshot<MapViewPosition?> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.hasPosition()) {
//            _log.info("I have a new position ${snapshot.data.toString()}");
            return _buildMapView(snapshot.data!);
          }
          return _buildNoPositionView();
        }
        if (widget.viewModel.mapViewPosition != null &&
            widget.viewModel.mapViewPosition!.hasPosition()) {
//          _log.info("I have an old position ${widget.mapModel.mapViewPosition.toString()}");
          return _buildMapView(widget.viewModel.mapViewPosition!);
        }
        return _buildNoPositionView();
      },
    );
  }

  Widget _buildNoPositionView() {
    return widget.viewModel.noPositionView!
        .buildNoPositionView(context, widget.mapModel, widget.viewModel);
  }

  Widget _buildMapView(MapViewPosition position) {
    List<Widget> _widgets = [];
    if (widget.mapModel.displayModel.backgroundColor !=
        Colors.transparent.value) {
      // draw the background first
      _widgets.add(
        CustomPaint(
          foregroundPainter: BackgroundPainter(
              position: position, displayModel: widget.mapModel.displayModel),
          child: Container(),
        ),
      );
    }

    // then draw the map
    _widgets.add(
      StreamBuilder<JobSet>(
        stream: _jobQueue.observeJobResult,
        builder: (BuildContext context, AsyncSnapshot<JobSet> snapshot) {
          //_log.info("Streambuilder called with ${snapshot.data}");
          _tileLayer.needsRepaint = true;
          return CustomPaint(
            foregroundPainter: TileLayerPainter(
                _tileLayer, position, widget.viewModel, snapshot.data),
            child: Container(),
          );
        },
      ),
    );

    // now draw all markers
    _widgets.addAll(_markerRenderer
        .map(
          (MarkerRenderer markerRenderer) =>
              ChangeNotifierProvider<MarkerDataStore>.value(
            child: Consumer<MarkerDataStore>(
              builder:
                  (BuildContext context, MarkerDataStore value, Widget? child) {
                return CustomPaint(
                  foregroundPainter: MarkerPainter(
                      position: position,
                      displayModel: widget.mapModel.displayModel,
                      markerRenderer: markerRenderer),
                  child: Container(),
                );
              },
            ),
            value: markerRenderer.dataStore,
          ),
        )
        .toList());

    _submitJobSet(widget.viewModel, position, _jobQueue);

    return Stack(
      key: _keyView,
      children: <Widget>[
        FlutterGestureDetector(
          viewModel: widget.viewModel,
          child: Stack(
            children: _widgets,
          ),
        ),
        StreamBuilder<TapEvent>(
          stream: widget.viewModel.observeTap,
          builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
            if (!snapshot.hasData) return Container();
            TapEvent event = snapshot.data!;
            return ContextMenu(
              mapModel: widget.mapModel,
              viewModel: widget.viewModel,
              position: position,
              event: event,
              contextMenuBuilder: widget.viewModel.contextMenuBuilder,
            );
          },
        ),
      ],
    );
  }

  void _submitJobSet(
      ViewModel viewModel, MapViewPosition mapViewPosition, JobQueue jobQueue) {
    if (viewModel.viewDimension == null) return;
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
//      needsRepaint = true;
    }
  }
}
