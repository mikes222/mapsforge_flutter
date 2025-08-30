import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';

/// Moves, shifts and rotates the screen.
/// Moves the screen so that the [mapPosition] is in the center of the screen
/// Shifts the screen because the center of the map may not be the center of the mpaPosition (because we do not want to redraw the map everytime).
/// Rotates the screen if the map should be rotated.
class TransformWidget extends StatelessWidget {
  final MapPosition mapPosition;

  final Size screensize;

  final Widget child;

  final Mappoint mapCenter;

  const TransformWidget({super.key, required this.mapPosition, required this.screensize, required this.mapCenter, required this.child});

  @override
  Widget build(BuildContext context) {
    Mappoint centerPosition = mapPosition.getCenter();
    double viewScaleFactor = MapsforgeSettingsMgr().getDeviceScaleFactor();
    // print(
    //     "center: ${mapCenter.x - centerPosition.x} / ${mapCenter.y - centerPosition.y}, scaleFactor ${viewModel.viewScaleFactor}, focal ${mapViewPosition.focalPoint}");
    return ClipRect(
      child: Transform.scale(
        scale: 1 / viewScaleFactor,
        child: Transform.translate(
          offset: Offset(screensize.width / 2, screensize.height / 2),
          child: Transform.scale(
            //scale for pinch'n'zoom (see FlutterGestureDetector._ScaleEvent)
            scale: mapPosition.scale,
            origin: mapPosition.focalPoint != null
                ? Offset(
                    -screensize.width / 2 - (screensize.width / 2 - mapPosition.focalPoint!.dx) * viewScaleFactor,
                    -screensize.height / 2 - (screensize.height / 2 - mapPosition.focalPoint!.dy) * viewScaleFactor,
                  )
                : null,
            child: Transform.rotate(
              // rotate if the map should be rotated
              angle: mapPosition.rotationRadian,
              origin: Offset(-screensize.width / 2, -screensize.height / 2),
              child: Transform.translate(
                // shift the map according the the centerposition set with viewModel.setPosition() et al
                offset: Offset((mapCenter.x - centerPosition.x), (mapCenter.y - centerPosition.y)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
