import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';

/// Listens to double-tap events on the map and zooms in around the position of the double tap. The listening event is configurable.
class ZoomInOverlay extends StatelessWidget {
  final MapModel mapModel;

  final TapEventListener tapEventListener;

  const ZoomInOverlay({super.key, required this.mapModel, this.tapEventListener = TapEventListener.doubleTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: tapEventListener.getStream(mapModel),
      builder: (BuildContext context, AsyncSnapshot<TapEvent?> snapshot) {
        if (snapshot.hasError) {
          return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
        if (snapshot.data == null) return const SizedBox();

        TapEvent event = snapshot.data!;
        // zoomin around the position of the tap would bring the tap-position to the center and zooming around the new center.
        // Instead we want to zoom so that the tap-position stays at the same position in the ui and everything around it zooms.
        MapPosition lastPosition = mapModel.lastPosition!;
        print("zoomin $event ${snapshot.connectionState}");
        mapModel.zoomInAround(
          (event.latitude - lastPosition.latitude) / 2 + lastPosition.latitude,
          (event.longitude - lastPosition.longitude) / 2 + lastPosition.longitude,
        );
        return const SizedBox();
      },
    );
  }
}
