import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/errorhelper_widget.dart';

class ZoomInOverlay extends StatelessWidget {
  final MapModel mapModel;

  final TapEventListener tapEventListener;

  const ZoomInOverlay({super.key, required this.mapModel, this.tapEventListener = TapEventListener.doubleTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: tapEventListener == TapEventListener.doubleTap
          ? mapModel.doubleTapStream
          : tapEventListener == TapEventListener.longTap
          ? mapModel.longTapStream
          : mapModel.tapStream,
      builder: (BuildContext context, AsyncSnapshot<TapEvent?> snapshot) {
        if (snapshot.hasError) {
          return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
        if (snapshot.data == null) return const SizedBox();

        TapEvent event = snapshot.data!;
        // zoomin around the position of the tap would bring the tap-position to the center and zooming around the new center.
        // Instead we want to zoom so that the tap-position stays at the same position in the ui and everything around it zooms.
        MapPosition lastPosition = mapModel.lastPosition!;
        mapModel.zoomInAround(
          (event.latitude - lastPosition.latitude) / 2 + lastPosition.latitude,
          (event.longitude - lastPosition.longitude) / 2 + lastPosition.longitude,
        );
        return const SizedBox();
      },
    );
  }
}
