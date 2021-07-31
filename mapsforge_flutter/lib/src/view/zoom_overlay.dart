import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

class ZoomOverlay extends StatefulWidget {
  final ViewModel viewModel;

  ZoomOverlay(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return _ZoomOverlayState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ZoomOverlayState extends State<ZoomOverlay> with SingleTickerProviderStateMixin {
  final double toolbarSpacing = 15;

  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

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
    return Positioned(
      bottom: toolbarSpacing,
      right: toolbarSpacing,
      top: toolbarSpacing,
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
              fillColor: Colors.white,
              child: Icon(Icons.add),
              padding: EdgeInsets.all(10.0),
              shape: CircleBorder(),
              constraints: BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(height: toolbarSpacing),
            RawMaterialButton(
              onPressed: () => widget.viewModel.zoomOut(),
              elevation: 2.0,
              fillColor: Colors.white,
              child: Icon(Icons.remove),
              padding: EdgeInsets.all(10.0),
              shape: CircleBorder(),
              constraints: BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
