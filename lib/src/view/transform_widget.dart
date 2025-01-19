import 'package:flutter/cupertino.dart';

import '../../core.dart';

class TransformWidget extends StatelessWidget {
  final ViewModel viewModel;

  final MapViewPosition mapViewPosition;

  final Size screensize;

  final Widget child;

  final Mappoint mapCenter;

  const TransformWidget(
      {super.key,
      required this.viewModel,
      required this.mapViewPosition,
      required this.screensize,
      required this.mapCenter,
      required this.child});

  @override
  Widget build(BuildContext context) {
    Mappoint centerPosition = mapViewPosition.getCenter();
    // print(
    //     "center: ${mapCenter.x - centerPosition.x} / ${mapCenter.y - centerPosition.y}, scaleFactor ${viewModel.viewScaleFactor}, focal ${mapViewPosition.focalPoint}");
    return ClipRect(
      child: Transform.scale(
        scale: 1 / viewModel.viewScaleFactor,
        child: Transform.translate(
          offset: Offset(screensize.width / 2, screensize.height / 2),
          child: Transform.scale(
            //scale for pinch'n'zoom (see FlutterGestureDetector._ScaleEvent)
            scale: mapViewPosition.scale,
            origin: mapViewPosition.focalPoint != null
                ? Offset(
                    -screensize.width / 2 -
                        (screensize.width / 2 -
                                mapViewPosition.focalPoint!.dx) *
                            viewModel.viewScaleFactor,
                    -screensize.height / 2 -
                        (screensize.height / 2 -
                                mapViewPosition.focalPoint!.dy) *
                            viewModel.viewScaleFactor)
                : null,
            child: Transform.rotate(
              // rotate if the map should be rotated
              angle: mapViewPosition.rotationRadian,
              origin: Offset(-screensize.width / 2, -screensize.height / 2),
              child: Transform.translate(
                // shift the map according the the centerposition set with viewModel.setPosition() et al
                offset: Offset((mapCenter.x - centerPosition.x),
                    (mapCenter.y - centerPosition.y)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
