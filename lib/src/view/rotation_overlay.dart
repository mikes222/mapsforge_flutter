import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

/// Two‐finger rotation overlay that never blocks pan/zoom,
/// but eases the rotation by blending 30% of the delta each move.
class RotationOverlay extends StatefulWidget {
  final ViewModel viewModel;

  /// degrees of twist before we start rotating
  final double thresholdDeg;

  /// 0.0 = no smoothing (instant), 1.0 = full smoothing (never move)
  final double smoothing;

  const RotationOverlay(
    this.viewModel, {
    Key? key,
    this.thresholdDeg = 10.0,
    this.smoothing = 0.3,
  }) : super(key: key);

  @override
  _RotationOverlayState createState() => _RotationOverlayState();
}

class _RotationOverlayState extends State<RotationOverlay> {
  final Map<int, Offset> _points = {};
  double? _baselineAngle;
  double _rawHeading = 0.0; 
  double _displayHeading = 0.0;

  double _normalize(double deg) {
    deg %= 360;
    return deg < 0 ? deg + 360 : deg;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _points[e.pointer] = e.position;
        if (_points.length == 2) {
          // both the raw & display start from the map's current heading
          _rawHeading = widget.viewModel.mapViewPosition?.rotation ?? 0.0;
          _displayHeading = _rawHeading;
          _baselineAngle = _computeTwoFingerAngle();
        }
      },
      onPointerMove: (e) {
        if (!_points.containsKey(e.pointer)) return;
        _points[e.pointer] = e.position;
        if (_points.length == 2 && _baselineAngle != null) {
          final newAngle = _computeTwoFingerAngle();
          var delta = newAngle - _baselineAngle!;
          if (delta > 180) delta -= 360;
          if (delta < -180) delta += 360;

          // only start rotating once you exceed the threshold
          if (delta.abs() < widget.thresholdDeg) return;

          // accumulate raw heading
          _rawHeading = _normalize(_rawHeading + delta);
          _baselineAngle = newAngle;

          // exponential smoothing towards rawHeading
          _displayHeading += (_rawHeading - _displayHeading) * widget.smoothing;

          widget.viewModel.rotate(_displayHeading);
        }
      },
      onPointerUp: (e) {
        _points.remove(e.pointer);
        if (_points.length < 2) _baselineAngle = null;
      },
      onPointerCancel: (e) {
        _points.remove(e.pointer);
        if (_points.length < 2) _baselineAngle = null;
      },
      child: const SizedBox.expand(),
    );
  }

  double _computeTwoFingerAngle() {
    final pts = _points.values.toList();
    final center = Offset(
      (pts[0].dx + pts[1].dx) / 2,
      (pts[0].dy + pts[1].dy) / 2,
    );
    final a0 = atan2(pts[0].dy - center.dy, pts[0].dx - center.dx);
    final a1 = atan2(pts[1].dy - center.dy, pts[1].dx - center.dx);
    // average the two angles and convert to degrees
    return _normalize(((a0 + a1) / 2) * 180 / pi);
  }
}
