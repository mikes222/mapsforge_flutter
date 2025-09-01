import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';

class MarkerDatastoreOverlay extends StatefulWidget {
  final MapModel mapModel;

  final MarkerDatastore datastore;

  final ZoomlevelRange zoomlevelRange;

  final int extendMeters;

  const MarkerDatastoreOverlay({super.key, required this.mapModel, required this.datastore, required this.zoomlevelRange, this.extendMeters = 5000});

  @override
  State<MarkerDatastoreOverlay> createState() => _MarkerDatastoreOverlayState();
}

//////////////////////////////////////////////////////////////////////////////

class _MarkerDatastoreOverlayState extends State<MarkerDatastoreOverlay> {
  BoundingBox? _cachedBoundingBox;

  int _cachedZoomlevel = -1;

  @override
  void didUpdateWidget(covariant MarkerDatastoreOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datastore != widget.datastore || oldWidget.zoomlevelRange != widget.zoomlevelRange) {
      _cachedZoomlevel = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size screensize = constraints.biggest;
        return StreamBuilder(
          stream: widget.mapModel.positionStream,
          builder: (BuildContext context, AsyncSnapshot<MapPosition> snapshot) {
            if (snapshot.error != null) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            if (snapshot.data == null) {
              return const SizedBox();
            }
            MapPosition position = snapshot.data!;
            if (_cachedZoomlevel == position.zoomlevel) {
              BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
              if (_cachedBoundingBox == null || !_cachedBoundingBox!.containsBoundingBox(boundingBox)) {
                boundingBox = boundingBox.extendMeters(widget.extendMeters);
                widget.datastore.askChangeBoundingBox(_cachedZoomlevel, boundingBox);
                _cachedBoundingBox = boundingBox;
              }
            }
            if (_cachedZoomlevel != position.zoomlevel) {
              BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
              boundingBox = boundingBox.extendMeters(widget.extendMeters);
              widget.datastore.askChangeZoomlevel(position.zoomlevel, boundingBox, position.projection);
              _cachedZoomlevel = position.zoomlevel;
              _cachedBoundingBox = boundingBox;
            }
            return TransformWidget(
              mapCenter: position.getCenter(),
              mapPosition: position,
              screensize: screensize,
              child: CustomPaint(foregroundPainter: MarkerDatastorePainter(position, widget.datastore), child: const SizedBox.expand()),
            );
          },
        );
      },
    );
  }
}
