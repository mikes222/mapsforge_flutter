import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

/// Shows a ruler in the left-bottom corner of the map to indicate distances of the map. The
/// color of the ruler and text is derived from ThemeData.textTheme.bodyText2
class DistanceOverlay extends StatefulWidget {
  final ViewModel viewModel;

  DistanceOverlay(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return _DistanceOverlayState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _DistanceOverlayState extends State<DistanceOverlay>
    with SingleTickerProviderStateMixin {
  final double toolbarSpacing = 15;

  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

  Timer? _timer;

  int? _lastDisplayed;

  int? _lastZoomLevel;

  double _pixel = 1;

  String _toDisplay = "unknown";

  @override
  DistanceOverlay get widget => super.widget;

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
    return Positioned(
      bottom: toolbarSpacing,
      left: toolbarSpacing,
      right: toolbarSpacing,
      // this widget has an unbound width
      // left: toolbarSpacing,
      child: FadeTransition(
        opacity: _fadeAnimationController,
        child: StreamBuilder(
          stream: widget.viewModel.observePosition,
          builder:
              (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SizedBox();
            if (snapshot.data == null) return const SizedBox();
            MapViewPosition position = snapshot.data!;
            if (position.zoomLevel != _lastZoomLevel) {
              // zoomLevel has changed. Enable showing the new ruler
              _lastDisplayed = null;
              _timer?.cancel();
              _timer = null;
              _fadeAnimationController.reset();
              _lastZoomLevel = position.zoomLevel;
              _recalc(position);
            }
            // if (_timer != null) {
            //   // still showing, do not recalculate
            //   return const SizedBox();
            // }

            if (_timer == null &&
                (_lastDisplayed == null ||
                    _lastDisplayed! <
                        DateTime.now().millisecondsSinceEpoch - 30 * 1000)) {
              _fadeAnimationController.forward();
              _timer?.cancel();
              _timer = Timer(const Duration(seconds: 10), () {
                if (mounted) _fadeAnimationController.reverse();
                _timer = null;
                _lastDisplayed = DateTime.now().millisecondsSinceEpoch;
              });
            }

            // we do not have any info, display nothing
            if (_pixel <= 10) return const SizedBox();
            // display the ruler and the corresponding text
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomPaint(
                  size: Size(_pixel, 8),
                  foregroundPainter: MeterPainter(
                      pixel: _pixel,
                      color: Theme.of(context).textTheme.bodyText2?.color ??
                          Colors.black),
                ),
                const SizedBox(height: 2),
                Text(_toDisplay, style: Theme.of(context).textTheme.bodyText2),
              ],
            );
          },
        ),
      ),
    );
  }

  void _recalc(MapViewPosition position) {
    // get the meters per pixel, always calculate with meters!
    if (position.latitude == null || position.longitude == null) return;
    double meterPerPixel = position.projection!
        .meterPerPixel(LatLong(position.latitude!, position.longitude!));
    // default is 100 pixels in ui
    _pixel = 100;
    // how many meters are that?
    double meter = meterPerPixel * _pixel;
    // now round to human-readable measures
    double roundedMeter = meter.round().toDouble();
    if (meter < 1) {
      roundedMeter = (meter * 10).roundToDouble() / 10;
    } else if (meter < 10) {
      roundedMeter = (meter).roundToDouble();
    } else if (meter < 100) {
      roundedMeter = (meter / 10).roundToDouble() * 10;
    } else if (meter < 1000) {
      roundedMeter = (meter / 50).roundToDouble() * 50;
    } else if (meter < 10000) {
      roundedMeter = (meter / 1000).roundToDouble() * 1000;
    } else if (meter < 100000) {
      roundedMeter = (meter / 10000).roundToDouble() * 10000;
    } else {
      roundedMeter = (meter / 100000).roundToDouble() * 100000;
    }
    // adapt the concrete number of pixel to display the correct size
    _pixel = _pixel * roundedMeter / meter;

    // how to display the meters to the user
    _toDisplay = "${roundedMeter.toStringAsFixed(0)} m";
    if (roundedMeter > 1000) {
      _toDisplay = "${(roundedMeter / 1000).toStringAsFixed(0)} km";
    } else if (roundedMeter < 1) {
      _toDisplay = "${(roundedMeter * 100).toStringAsFixed(0)} cm";
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class MeterPainter extends CustomPainter {
  final double pixel;

  final Color color;

  MeterPainter({required this.pixel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Paint paint = Paint();
    paint.color = color;
    paint.strokeWidth = 4;
    paint.style = ui.PaintingStyle.stroke;

    final ui.Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, 8);
    path.lineTo(pixel, 8);
    path.lineTo(pixel, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MeterPainter oldDelegate) {
//    if (oldDelegate?.position != position) return true;
    return false;
  }

  @override
  bool shouldRebuildSemantics(MeterPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
