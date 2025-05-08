import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

/// Two‐finger rotation overlay that never blocks pan/zoom,
/// and uses ViewModel.rotateDelta() to apply each twist incrementally.
class RotationOverlay extends StatefulWidget {
  final ViewModel viewModel;

  /// degrees of twist before we start rotating
  final double thresholdDeg;

  const RotationOverlay(
    this.viewModel, {
    Key? key,
    this.thresholdDeg = 10.0,
  }) : super(key: key);

  @override
  _RotationOverlayState createState() => _RotationOverlayState();
}

class _RotationOverlayState extends State<RotationOverlay> {
  final Map<int, Offset> _points = {};
  double? _baselineAngle;
  bool _rotating = false;

  double _normalize(double deg) {
    deg %= 360;
    return deg < 0 ? deg + 360 : deg;
  }

  double _twoFingerAngle() {
    final pts = _points.values.toList();
    final cx = (pts[0].dx + pts[1].dx) / 2;
    final cy = (pts[0].dy + pts[1].dy) / 2;
    final a0 = atan2(pts[0].dy - cy, pts[0].dx - cx);
    final a1 = atan2(pts[1].dy - cy, pts[1].dx - cx);
    // average, converted to degrees
    return _normalize(((a0 + a1) / 2) * 180 / pi);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _points[e.pointer] = e.position;
        if (_points.length == 2) {
          _baselineAngle = _twoFingerAngle();
          _rotating = false;
        }
      },
      onPointerMove: (e) {
        if (!_points.containsKey(e.pointer)) return;
        _points[e.pointer] = e.position;

        if (_points.length == 2 && _baselineAngle != null) {
          final newAngle = _twoFingerAngle();
          var delta = newAngle - _baselineAngle!;
          if (delta > 180) delta -= 360;
          if (delta < -180) delta += 360;

          // threshold guard
          if (!_rotating) {
            if (delta.abs() > widget.thresholdDeg) {
              _rotating = true;
            } else {
              return; // still just pinch/drag
            }
          }

          // apply only the incremental twist
          widget.viewModel.rotateDelta(delta);

          // reset baseline for the next small delta
          _baselineAngle = newAngle;
        }
      },
      onPointerUp: (e) {
        _points.remove(e.pointer);
        if (_points.length < 2) {
          _rotating = false;
          _baselineAngle = null;
        }
      },
      onPointerCancel: (e) {
        _points.remove(e.pointer);
        if (_points.length < 2) {
          _rotating = false;
          _baselineAngle = null;
        }
      },
      child: const SizedBox.expand(),
    );
  }
}
