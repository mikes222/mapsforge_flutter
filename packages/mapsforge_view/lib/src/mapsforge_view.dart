import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/context_menu/context_menu_overlay.dart';
import 'package:mapsforge_view/src/gesture/double_tap_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/move_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/rotation_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/scale_gesture_detector.dart';
import 'package:mapsforge_view/src/gesture/tap_gesture_detector.dart';
import 'package:mapsforge_view/src/overlay/distance_overlay.dart';
import 'package:mapsforge_view/src/overlay/indoorlevel_overlay.dart';
import 'package:mapsforge_view/src/overlay/zoom_in_overlay.dart';
import 'package:mapsforge_view/src/overlay/zoom_overlay.dart';

/// Default view for many features of mapsforge. If you want to add or remove these features, just copy the stack() to your own application.
class MapsforgeView extends StatelessWidget {
  final MapModel mapModel;

  const MapsforgeView({super.key, required this.mapModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // move the map
        MoveGestureDetector(mapModel: mapModel),
        // rotates the map when two fingers are pressed and rotated
        RotationGestureDetector(mapModel: mapModel),
        // scales the map when two fingers are pressed and zoomed
        ScaleGestureDetector(mapModel: mapModel),
        // informs mapModel about double tap gestures
        DoubleTapGestureDetector(mapModel: mapModel),
        // informs mapModel about short and long taps
        TapGestureDetector(mapModel: mapModel),
        // Shows tiles according to the current position
        TileView(mapModel: mapModel),
        // Shows labels (and rotate them) according to the current position (if the renderer supports it)
        if (mapModel.renderer.supportLabels()) LabelView(mapModel: mapModel),
        // Shows a ruler with distance information in the left-bottom corner of the map
        DistanceOverlay(mapModel: mapModel),
        // Shows zoom-in and zoom-out buttons
        ZoomOverlay(mapModel: mapModel),
        // listens to double-click events (configurable) and zooms in
        ZoomInOverlay(mapModel: mapModel),
        // shows the indoorlevel zoom buttons
        IndoorlevelOverlay(mapModel: mapModel),
        // listens to tap events (configurable) and shows a context menu (also configurable)
        ContextMenuOverlay(mapModel: mapModel),
      ],
    );
  }
}
