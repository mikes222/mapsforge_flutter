import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/gesture.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/overlay.dart';

/// Default view for many features of mapsforge. If you want to add or remove these features, just copy the stack() to your own application and modify it
/// accordingly.
class MapsforgeView extends StatelessWidget {
  final MapModel mapModel;

  late final List<Widget> _children;

  final ContextMenuBuilder? contextMenuBuilder;

  MapsforgeView({super.key, required this.mapModel, List<Widget>? children, this.contextMenuBuilder}) {
    if (children != null) {
      _children = children;
    } else {
      _children = [
        // Shows a ruler with distance information in the left-bottom corner of the map
        DistanceOverlay(mapModel: mapModel),
        // Shows zoom-in and zoom-out buttons
        ZoomOverlay(mapModel: mapModel),
        // shows the indoorlevel zoom buttons
        IndoorlevelOverlay(mapModel: mapModel),
        // shows an icon in the right-upper corner to reset rotation if rotation is active
        RotationResetOverlay(mapModel: mapModel),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // recognizes single-tap, double-tap and long-taps, moves the map, handles drag'n'drop, rotation and scaling
        GenericGestureDetector(mapModel: mapModel),
        // Shows tiles according to the current position
        TileView(mapModel: mapModel),
        // Shows labels (and rotate them) according to the current position (if the renderer supports it)
        if (mapModel.renderer.supportLabels()) LabelView(mapModel: mapModel),
        // listens to double-click events (configurable) and zooms in
        ZoomInOverlay(mapModel: mapModel),
        // shows additional overlays or custom overlays
        ..._children,
        // listens to tap events (configurable) and shows a context menu (also configurable)
        ContextMenuOverlay(mapModel: mapModel, contextMenuBuilder: contextMenuBuilder),
        NoPositionOverlay(mapModel: mapModel),
      ],
    );
  }
}
