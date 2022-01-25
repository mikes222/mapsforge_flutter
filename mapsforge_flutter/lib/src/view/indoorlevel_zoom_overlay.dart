import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

class IndoorlevelZoomOverlay extends StatefulWidget {
  final ViewModel viewModel;

  final Map<int, String?>? indoorLevels;

  IndoorlevelZoomOverlay(this.viewModel, {this.indoorLevels});

  @override
  State<StatefulWidget> createState() {
    return _IndoorlevelZoomOverlayState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _IndoorlevelZoomOverlayState extends State<IndoorlevelZoomOverlay>
    with SingleTickerProviderStateMixin {
  final double toolbarSpacing = 15;

  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

  @override
  IndoorlevelZoomOverlay get widget => super.widget;

  @override
  void initState() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      //value: 1,
      vsync: this,
      //lowerBound: 0,
      //upperBound: 1,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.ease,
    );

    super.initState();
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
          children: <Widget>[
            Flexible(
              child: IndoorLevelBar(
                onChange: (int level) {
                  widget.viewModel.setIndoorLevel(level);
                },
                indoorLevels: widget.indoorLevels ??
                    {
                      5: null,
                      4: null,
                      3: null,
                      2: "OG2",
                      1: "OG1",
                      0: "EG",
                      -1: "UG1",
                      -2: null,
                      -3: null,
                      -4: null,
                      -5: null
                    },
                width: 45,
                fillColor: Colors.white,
                elevation: 2.0,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                initialLevel: widget.viewModel.getIndoorLevel(),
              ),
            ),
            SizedBox(height: toolbarSpacing),
            RawMaterialButton(
              onPressed: () => widget.viewModel.zoomIn(),
              elevation: 2.0,
              fillColor: Colors.white,
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
              fillColor: Colors.white,
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
