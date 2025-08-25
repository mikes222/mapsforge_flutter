import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_view/src/overlay/context_menu_overlay.dart';
import 'package:mapsforge_view/src/overlay/simple_context_menu_widget.dart';

/// A context menu with a frame and the position (lat/lon) where the user tapped at the map. The position can be copied into clipboard with a long press.
class SimpleContextMenu extends StatelessWidget {
  final ContextMenuInfo info;

  const SimpleContextMenu({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return SimpleContextMenuWidget(
      info: info,
      child: InkWell(
        onTap: () {
          info.mapModel.tap(null);
        },
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: "${info.latitude.toStringAsFixed(6)}, ${info.longitude.toStringAsFixed(6)}"));
        },
        child: Text("${info.latitude.toStringAsFixed(6)} / ${info.longitude.toStringAsFixed(6)}"),
      ),
    );
  }
}
