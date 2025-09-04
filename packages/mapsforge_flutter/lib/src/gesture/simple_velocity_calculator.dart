import 'dart:ui';

import 'package:mapsforge_flutter/src/gesture/velocity_calculator.dart';

/// Calculates a smoothed velocity from a stream of Offset events using a rolling average.
///
/// This approach is simple and effective for many use cases where high
/// precision isn't critical.
class SimpleVelocityCalculator {
  final int maxEvents;
  final _events = <TimedOffset>[];

  Velocity lastVelocity = Velocity(x: 0.0, y: 0.0);

  SimpleVelocityCalculator({this.maxEvents = 5}) {
    assert(maxEvents > 1, 'maxEvents must be greater than 1');
  }

  /// Adds a new Offset and its timestamp to the calculation queue.
  void addEvent(Offset offset) {
    _events.add(TimedOffset(offset, DateTime.now().millisecondsSinceEpoch));
    if (_events.length > maxEvents) {
      _events.removeAt(0);
    }
    _calculateVelocity();
  }

  void _calculateVelocity() {
    if (_events.length < 2) {
      lastVelocity = (Velocity(x: 0.0, y: 0.0));
      return;
    }

    // Get the first and last event in the current window.
    final first = _events.first;
    final last = _events.last;

    final double deltaX = last.offset.dx - first.offset.dx;
    final double deltaY = last.offset.dy - first.offset.dy;
    final int deltaTime = last.timestamp - first.timestamp;

    if (deltaTime == 0) {
      lastVelocity = (Velocity(x: 0.0, y: 0.0));
      return;
    }

    final velocityX = deltaX / deltaTime;
    final velocityY = deltaY / deltaTime;

    lastVelocity = (Velocity(x: velocityX, y: velocityY));
  }
}
