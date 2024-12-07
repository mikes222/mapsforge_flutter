import 'package:flutter/cupertino.dart';

import '../../core.dart';

class TransformWidget extends StatelessWidget {
  final ViewModel viewModel;

  final MapViewPosition mapViewPosition;

  final Size screensize;

  final Widget child;

  final Mappoint centerTile;

  const TransformWidget(
      {super.key,
      required this.viewModel,
      required this.mapViewPosition,
      required this.screensize,
      required this.centerTile,
      required this.child});

  @override
  Widget build(BuildContext context) {
    Mappoint centerPosition = mapViewPosition.getCenter();
    return ClipRect(
      child: Transform.scale(
        scale: 1 / viewModel.viewScaleFactor,
        child: Transform.scale(
          scale: mapViewPosition.scale,
          origin: mapViewPosition.focalPoint != null
              ? Offset(mapViewPosition.focalPoint!.dx - screensize.width / 2,
                  mapViewPosition.focalPoint!.dy - screensize.height / 2)
              : null,
          child: Transform.rotate(
            angle: mapViewPosition.rotationRadian,
            child: Transform.translate(
              offset: Offset(
                  (centerTile.x - centerPosition.x + screensize.width / 2),
                  (centerTile.y - centerPosition.y + screensize.height / 2)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
