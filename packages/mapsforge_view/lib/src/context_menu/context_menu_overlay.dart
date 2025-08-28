import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/context_menu/simple_context_menu.dart';

typedef ContextMenuBuilder = Widget Function(ContextMenuInfo info);

/// Listens to tap events on the map and shows a context menu. The event which is being listened is configurable. The context menu to show is also
/// configurable.
class ContextMenuOverlay extends StatelessWidget {
  final MapModel mapModel;

  /// The builder for a widget which represents the context menu. The widget must position itself as desired.
  final ContextMenuBuilder? contextMenuBuilder;

  final TapEventListener tapEventListener;

  const ContextMenuOverlay({super.key, required this.mapModel, this.contextMenuBuilder, this.tapEventListener = TapEventListener.singleTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return StreamBuilder(
          stream: tapEventListener.getStream(mapModel),
          builder: (BuildContext context, AsyncSnapshot<TapEvent?> snapshot) {
            if (snapshot.hasError) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            // null event, close the context menu
            if (snapshot.data == null) return const SizedBox();
            // we have a tap event. Let us listen to the current map position and show the context menu.
            TapEvent event = snapshot.data!;
            return StreamBuilder(
              stream: mapModel.positionStream,
              builder: (BuildContext context, AsyncSnapshot<MapPosition> snapshot) {
                if (snapshot.hasError) {
                  return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
                }
                if (snapshot.data == null) return const SizedBox();
                MapPosition position = snapshot.data!;

                Mappoint center = position.getCenter();

                /// distance from the center
                Mappoint mappoint = event.mappoint;
                double diffX = mappoint.x - center.x;
                double diffY = mappoint.y - center.y;

                // mappoints and center are deviceScale-dependent, but context menu is not.
                diffX = diffX / MapsforgeSettingsMgr().getDeviceScaleFactor();
                diffY = diffY / MapsforgeSettingsMgr().getDeviceScaleFactor();

                if (mapModel.lastPosition?.rotation != 0) {
                  double hyp = sqrt(diffX * diffX + diffY * diffY);
                  double rad = atan2(diffY, diffX);
                  double rot = mapModel.lastPosition!.rotationRadian;
                  diffX = cos(rot + rad) * hyp;
                  diffY = sin(rot + rad) * hyp;

                  // print(
                  //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
                }

                double halfWidth = constraints.biggest.width / 2;
                double halfHeight = constraints.biggest.height / 2;

                ContextMenuInfo contextMenuInfo = ContextMenuInfo(
                  mapModel: mapModel,
                  halfScreenWidth: halfWidth,
                  halfScreenHeight: halfHeight,
                  diffX: diffX,
                  diffY: diffY,
                  event: event,
                );
                return contextMenuBuilder != null ? contextMenuBuilder!(contextMenuInfo) : SimpleContextMenu(info: contextMenuInfo);
              },
            );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

class ContextMenuInfo {
  final MapModel mapModel;

  final double halfScreenWidth;

  final double halfScreenHeight;

  final double diffX;

  final double diffY;

  final TapEvent event;

  ContextMenuInfo({
    required this.mapModel,
    required this.halfScreenWidth,
    required this.halfScreenHeight,
    required this.diffX,
    required this.diffY,
    required this.event,
  });

  ILatLong get latLong => LatLong(event.latitude, event.longitude);

  double get latitude => event.latitude;

  double get longitude => event.longitude;

  PixelProjection get projection => event.projection;

  @override
  String toString() {
    return 'ContextMenuInfo{halfScreenWidth: $halfScreenWidth, halfScreenHeight: $halfScreenHeight, diffX: $diffX, diffY: $diffY}';
  }
}
