import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

/// Shows zoom-in and zoom-out buttons
class ZoomOverlay extends StatefulWidget {
  final ViewModel viewModel;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  

  ZoomOverlay(this.viewModel, {this.top, this.right, this.bottom, this.left}) :
  assert(!(top != null && bottom != null)),
  assert(!(right != null && left != null));

  @override
  State<StatefulWidget> createState() {
    return _ZoomOverlayState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ZoomOverlayState extends State<ZoomOverlay>
    with SingleTickerProviderStateMixin {
  final double toolbarSpacing = 15;

  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

  @override
  ZoomOverlay get widget => super.widget;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      //value: 1,
      vsync: this,
      //lowerBound: 0,
      //upperBound: 1,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _fadeAnimationController.forward();

    final brightness = MediaQuery.platformBrightnessOf(context);
    final fillColor = Theme.of(context).buttonTheme.colorScheme?.surface ?? 
      (brightness == Brightness.light ? Colors.white : Colors.black);

    return Positioned(
      top: widget.top != null ? max(widget.top!, toolbarSpacing) : null,
      right: (widget.right == null && widget.left == null)
          ? toolbarSpacing
          : widget.right != null
              ? max(widget.right!, toolbarSpacing)
              : null,
      bottom: (widget.top == null && widget.bottom == null)
          ? toolbarSpacing
          : widget.bottom != null
              ? max(widget.bottom!, toolbarSpacing)
              : null,
      left: widget.left != null ? max(widget.left!, toolbarSpacing) : null,

      //top: toolbarSpacing,
      // this widget has an unbound width
      // left: toolbarSpacing,
      child: FadeTransition(
        opacity: _fadeAnimationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            RawMaterialButton(
              onPressed: () => widget.viewModel.zoomIn(),
              elevation: 2.0,
              fillColor: fillColor,
              child: const Icon(Icons.add),
              padding: const EdgeInsets.all(10.0),
              shape: const CircleBorder(),
              constraints: const BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(height: toolbarSpacing),
            RawMaterialButton(
              onPressed: () => widget.viewModel.zoomOut(),
              elevation: 2.0,
              fillColor: fillColor,
              child: const Icon(Icons.remove),
              padding: const EdgeInsets.all(10.0),
              shape: const CircleBorder(),
              constraints: const BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
