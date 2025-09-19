import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/context_menu.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

/// A context menu with a frame and the position (lat/lon) where the user tapped at the map. The position can be copied into clipboard with a long press.
class SimpleContextMenu extends StatelessWidget {
  final ContextMenuInfo info;

  final Widget? child;

  final MapModel? mapModel;

  const SimpleContextMenu({super.key, required this.info, this.child, this.mapModel});

  @override
  Widget build(BuildContext context) {
    if (info.diffX < -info.halfScreenWidth ||
        info.diffX > 3 * info.halfScreenWidth ||
        info.diffY < -info.halfScreenHeight ||
        info.diffY > 3 * info.halfScreenHeight) {
      info.mapModel.tap(null);
      return const SizedBox();
    }
    return SimpleContextMenuWidget(
      info: info,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              info.mapModel.tap(null);
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: "${info.latitude.toStringAsFixed(6)}, ${info.longitude.toStringAsFixed(6)}"));
            },
            // use a column to make the ink area a bit bigger
            child: Column(
              children: [
                Row(
                  children: [
                    Text("${info.latitude.toStringAsFixed(6)} / ${info.longitude.toStringAsFixed(6)}"),
                    const SizedBox(width: 12),
                    if (mapModel != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          mapModel!.tap(null);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
