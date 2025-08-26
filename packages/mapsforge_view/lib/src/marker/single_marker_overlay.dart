import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/marker/marker.dart';
import 'package:mapsforge_view/src/marker/single_marker_painter.dart';
import 'package:mapsforge_view/src/transform_widget.dart';

class SingleMarkerOverlay extends StatefulWidget {
  final MapModel mapModel;

  final Marker marker;

  const SingleMarkerOverlay({super.key, required this.mapModel, required this.marker});

  @override
  State<SingleMarkerOverlay> createState() => _SingleMarkerOverlayState();
}

//////////////////////////////////////////////////////////////////////////////

class _SingleMarkerOverlayState extends State<SingleMarkerOverlay> {
  int _lastZoomlevel = -1;

  @override
  void didUpdateWidget(covariant SingleMarkerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marker != widget.marker) {
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
            return FutureBuilder(
              future: _checkZoomlevel(position),
              builder: (BuildContext context, asyncSnapshot) {
                if (snapshot.error != null) {
                  return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
                }
                if (_lastZoomlevel != position.zoomlevel) return const SizedBox();
                return TransformWidget(
                  mapCenter: position.getCenter(),
                  mapPosition: position,
                  screensize: screensize,
                  child: CustomPaint(foregroundPainter: SingleMarkerPainter(position, widget.marker), child: const SizedBox.expand()),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _checkZoomlevel(MapPosition position) async {
    if (_lastZoomlevel != position.zoomlevel) {
      await widget.marker.changeZoomlevel(position.zoomlevel, position.projection);
      _lastZoomlevel = position.zoomlevel;
    }
    return true;
  }
}
