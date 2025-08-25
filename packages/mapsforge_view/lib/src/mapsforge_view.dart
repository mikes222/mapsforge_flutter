import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/gesture/double_tap_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/move_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/rotation_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/scale_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/tap_gesture_detector.dart';
import 'package:mapsforge_view/src/label/label_view.dart';
import 'package:mapsforge_view/src/overlay/context_menu_overlay.dart';
import 'package:mapsforge_view/src/overlay/distance_overlay.dart';
import 'package:mapsforge_view/src/overlay/indoorlevel_zoom_overlay.dart';
import 'package:mapsforge_view/src/overlay/zoom_in_overlay.dart';
import 'package:mapsforge_view/src/overlay/zoom_overlay.dart';

class MapsforgeView extends StatelessWidget {
  final MapModel mapModel;

  const MapsforgeView({super.key, required this.mapModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MoveGestureDetector(mapModel: mapModel),
        DoubleTapGestureDetector(mapModel: mapModel),
        RotationGestureDetector(mapModel: mapModel),
        ScaleGestureDetector(mapModel: mapModel),
        TapGestureDetector(mapModel: mapModel),
        TileView(mapModel: mapModel),
        if (mapModel.renderer.supportLabels()) LabelView(mapModel: mapModel),
        DistanceOverlay(mapModel: mapModel),
        ZoomOverlay(mapModel: mapModel),
        ZoomInOverlay(mapModel: mapModel),
        IndoorlevelZoomOverlay(mapModel: mapModel),
        ContextMenuOverlay(mapModel: mapModel),
      ],
    );
  }
}
