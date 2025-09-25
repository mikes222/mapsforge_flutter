import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

class RotationGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// degrees of twist before we start rotating
  final double thresholdDeg;

  /// If true, rotation gestures are ignored (pan/zoom unaffected).
  final bool locked;

  /// Optional reset control widget.
  final Widget? resetChild;

  /// Use Positioned() style placement; null values are ignored.
  final double? left, top, right, bottom;

  /// Padding around the reset control (inside the Positioned area).
  final EdgeInsetsGeometry resetPadding;

  /// Hide resetChild when map rotation is effectively zero.
  final bool hideResetWhenZero;

  /// Epsilon to consider "not rotated".
  final double zeroEpsilonDeg;

  /// Preferred: listenable rotation in degrees, used to drive visibility.
  final ValueListenable<double>? rotationDeg;

  /// Fallback: compute "is rotated" on demand (used if [rotationDeg] is null).
  final bool Function()? isRotated;

  /// Degrees to reset to when tapped. Ignored if [onReset] is provided.
  final double resetToDegrees;

  final bool wrapResetChildTap;

  /// Optional custom reset handler.
  final VoidCallback? onReset;

  const RotationGestureDetector({
    super.key,
    required this.mapModel,
    this.thresholdDeg = 10.0,
    this.locked = false,
    this.resetChild,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.resetPadding = const EdgeInsets.all(12),
    this.hideResetWhenZero = true,
    this.zeroEpsilonDeg = 0.5,
    this.rotationDeg,
    this.isRotated,
    this.resetToDegrees = 0.0,
    this.onReset,
    this.wrapResetChildTap = true,
  });

  @override
  State<RotationGestureDetector> createState() =>
      _RotationGestureDetectorState();
}

class _RotationGestureDetectorState extends State<RotationGestureDetector> {
  final Map<int, Offset> _points = {};
  double? _baselineAngle;
  bool _rotating = false;

  double _normalize(double deg) {
    deg %= 360;
    return deg < 0 ? deg + 360 : deg;
  }

  double _twoFingerAngle() {
    final pts = _points.values.toList();
    final theta = atan2(pts[1].dy - pts[0].dy, pts[1].dx - pts[0].dx);
    return _normalize(theta * 180 / pi);
  }

  void _performReset() {
    if (widget.onReset != null) {
      widget.onReset!();
    } else {
      try {
        widget.mapModel.rotateTo(widget.resetToDegrees);
      } catch (_) {
        // No-op fallback.
      }
    }
    _rotating = false;
    _baselineAngle = null;
    setState(() {}); // in case visibility depends on rebuild
  }

  Widget _buildGestureOverlay() {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (widget.locked) return;
        _points[e.pointer] = e.position;
        if (_points.length == 2) {
          _baselineAngle = _twoFingerAngle();
          _rotating = false;
        }
      },
      onPointerMove: (e) {
        if (widget.locked) return;
        if (!_points.containsKey(e.pointer)) return;
        _points[e.pointer] = e.position;

        if (_points.length == 2 && _baselineAngle != null) {
          final newAngle = _twoFingerAngle();
          var delta = newAngle - _baselineAngle!;
          if (delta > 180) delta -= 360;
          if (delta < -180) delta += 360;

          if (!_rotating) {
            if (delta.abs() > widget.thresholdDeg) {
              _rotating = true;
            } else {
              return; // still pinch/drag
            }
          }

          widget.mapModel.rotateBy(delta);
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

  bool _computeIsRotated() {
    if (!widget.hideResetWhenZero) return true;
    if (widget.rotationDeg != null) {
      return widget.rotationDeg!.value.abs() > widget.zeroEpsilonDeg;
    }
    if (widget.isRotated != null) {
      return widget.isRotated!();
    }
    // If we can’t know, default to showing it.
    return true;
  }

  Widget _positionedResetChild(Widget child) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom,
      child: Padding(
        padding: widget.resetPadding,
        child: widget.wrapResetChildTap
            ? GestureDetector(onTap: _performReset, child: widget.resetChild!)
            : widget.resetChild!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _buildGestureOverlay();

    if (widget.resetChild == null) {
      return overlay;
    }

    // If we have a listenable rotation, use it to rebuild/hide automatically.
    if (widget.rotationDeg != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          overlay,
          ValueListenableBuilder<double>(
            valueListenable: widget.rotationDeg!,
            builder: (_, angle, __) {
              final visible =
                  !widget.hideResetWhenZero ||
                  angle.abs() > widget.zeroEpsilonDeg;
              if (!visible) return const SizedBox.shrink();
              return _positionedResetChild(widget.resetChild!);
            },
          ),
        ],
      );
    }

    // Fallback: single-shot check; parent should rebuild when rotation changes.
    final visible = _computeIsRotated();
    return Stack(
      fit: StackFit.expand,
      children: [
        overlay,
        if (visible) _positionedResetChild(widget.resetChild!),
      ],
    );
  }
}
