import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

class RotationOverlay extends StatefulWidget {
  final ViewModel viewModel;
  const RotationOverlay(this.viewModel, {super.key});

  @override
  _RotationOverlayState createState() => _RotationOverlayState();
}

class _RotationOverlayState extends State<RotationOverlay> {
  // Store active pointer positions.
  final Map<int, Offset> _pointerPositions = {};

  // The baseline average angle (in degrees) computed from pointers.
  double? _baselineAngle;

  /// Normalize an angle to the range [0, 360).
  double _normalizeRotation(double rotation) {
    double normalized = rotation % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  /// Compute the average angle (in degrees) of all pointers.
  /// The average angle is computed by first determining the centroid of all pointers
  /// and then averaging the angles (via vector addition) from the centroid to each pointer.
  double _computeAverageAngle(Map<int, Offset> pointers) {
    if (pointers.isEmpty) return 0.0;
    // Compute centroid.
    double sumX = 0, sumY = 0;
    for (var pos in pointers.values) {
      sumX += pos.dx;
      sumY += pos.dy;
    }
    final centroid = Offset(sumX / pointers.length, sumY / pointers.length);

    double sumSin = 0, sumCos = 0;
    for (var pos in pointers.values) {
      double angle = atan2(pos.dy - centroid.dy, pos.dx - centroid.dx);
      sumSin += sin(angle);
      sumCos += cos(angle);
    }
    double avgAngle = atan2(sumSin, sumCos);
    // Convert to degrees and normalize.
    return _normalizeRotation(avgAngle * 180 / pi);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointerPositions[event.pointer] = event.position;
        // When three or more pointers are active, compute the average baseline angle.
        if (_pointerPositions.length >= 3) {
          _baselineAngle = _computeAverageAngle(_pointerPositions);
        }
      },
      onPointerMove: (event) {
        if (_pointerPositions.containsKey(event.pointer)) {
          _pointerPositions[event.pointer] = event.position;
          if (_pointerPositions.length >= 3 && _baselineAngle != null) {
            double newAverageAngle = _computeAverageAngle(_pointerPositions);
            double delta = newAverageAngle - _baselineAngle!;
            // Handle the wrap-around at 360°.
            if (delta > 180) {
              delta -= 360;
            } else if (delta < -180) {
              delta += 360;
            }
            _baselineAngle = newAverageAngle;
            widget.viewModel.rotateDelta(delta);
          }
        }
      },
      onPointerUp: (event) {
        _pointerPositions.remove(event.pointer);
        if (_pointerPositions.length < 3) {
          _baselineAngle = null;
        }
      },
      onPointerCancel: (event) {
        _pointerPositions.remove(event.pointer);
        if (_pointerPositions.length < 3) {
          _baselineAngle = null;
        }
      },
      // Only intercept touches when three or more pointers are active.
      child: _pointerPositions.length >= 3 ? Container(color: Colors.transparent) : IgnorePointer(child: Container(color: Colors.transparent)),
    );
  }
}
