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

  const MarkerDatastoreOverlay({super.key, required this.mapModel, required this.datastore});

  @override
  State<MarkerDatastoreOverlay> createState() => _MarkerDatastoreOverlayState();
}

//////////////////////////////////////////////////////////////////////////////

class _MarkerDatastoreOverlayState extends State<MarkerDatastoreOverlay> {
  int _lastZoomlevel = -1;

  @override
  void didUpdateWidget(covariant MarkerDatastoreOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datastore != widget.datastore) {
      _lastZoomlevel = -1;
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
            if (_lastZoomlevel == position.zoomlevel) {
              BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
              widget.datastore.askChangeBoundingBox(boundingBox);
              return TransformWidget(
                mapCenter: position.getCenter(),
                mapPosition: position,
                screensize: screensize,
                child: CustomPaint(foregroundPainter: MarkerDatastorePainter(position, widget.datastore), child: const SizedBox.expand()),
              );
            }
            return FutureBuilder(
              future: _checkZoomlevel(position, screensize),
              builder: (BuildContext context, asyncSnapshot) {
                if (snapshot.error != null) {
                  return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
                }
                if (_lastZoomlevel != position.zoomlevel) return const SizedBox();
                BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
                widget.datastore.askChangeBoundingBox(boundingBox);
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
      },
    );
  }

  Future<bool> _checkZoomlevel(MapPosition position, Size screensize) async {
    if (_lastZoomlevel != position.zoomlevel) {
      BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
      await widget.datastore.askChangeZoomlevel(position.zoomlevel, boundingBox, position.projection);
      _lastZoomlevel = position.zoomlevel;
    }
    return true;
  }
}
