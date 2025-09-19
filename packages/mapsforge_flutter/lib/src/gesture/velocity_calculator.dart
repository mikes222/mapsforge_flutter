import 'dart:math';
import 'dart:ui';

/// A data class to hold an Offset and its corresponding timestamp.
class TimedOffset {
  final Offset offset;
  final int timestamp;

  TimedOffset(this.offset, this.timestamp);
}

//////////////////////////////////////////////////////////////////////////////

/// Represents the velocity in pixels per millisecond for both x and y coordinates.
class Velocity {
  final double x;
  final double y;

  Velocity({this.x = 0.0, this.y = 0.0});

  double get pixelPerMillisecond {
    return sqrt(x * x + y * y);
  }

  Offset get offsetPerMillisecond => Offset(x, y);

  @override
  String toString() => 'Velocity(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';
}
