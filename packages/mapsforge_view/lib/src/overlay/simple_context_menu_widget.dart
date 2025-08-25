import 'package:flutter/material.dart';
import 'package:mapsforge_view/src/overlay/context_menu_overlay.dart';

/// A widget to draw a frame which points to the tapped position.
class SimpleContextMenuWidget extends StatelessWidget {
  final ContextMenuInfo info;

  final double outerRadius;

  final Widget child;

  const SimpleContextMenuWidget({super.key, required this.info, this.outerRadius = 20, required this.child});

  @override
  Widget build(BuildContext context) {
    Radius outer = Radius.circular(outerRadius);
    return Stack(
      children: [
        Positioned(
          left: info.diffX <= 0 ? info.halfScreenWidth + info.diffX : null,
          top: info.diffY <= 0 ? info.halfScreenHeight + info.diffY : null,
          right: info.diffX > 0 ? info.halfScreenWidth - info.diffX : null,
          bottom: info.diffY > 0 ? info.halfScreenHeight - info.diffY : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: info.diffX <= 0 && info.diffY <= 0 ? Radius.zero : outer,
                topRight: info.diffX > 0 && info.diffY <= 0 ? Radius.zero : outer,
                bottomLeft: info.diffX <= 0 && info.diffY > 0 ? Radius.zero : outer,
                bottomRight: info.diffX > 0 && info.diffY > 0 ? Radius.zero : outer,
              ),
              border: Border.all(color: Theme.of(context).primaryColor, width: 4),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ],
    );
  }
}
