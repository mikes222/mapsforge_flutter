import 'dart:async';
import 'dart:ui';

import 'package:mapsforge_flutter/src/gesture/velocity_calculator.dart';

/// A simple Kalman filter for a 1D state.
class _KalmanFilter1D {
  double _state;
  double _covariance;
  final double _measurementNoise;
  final double _processNoise;

  _KalmanFilter1D({double initialValue = 0.0, double initialUncertainty = 1.0, required double measurementNoise, required double processNoise})
    : _state = initialValue,
      _covariance = initialUncertainty,
      _measurementNoise = measurementNoise,
      _processNoise = processNoise;

  /// Predicts the next state based on the current state.
  void predict() {
    _covariance += _processNoise;
  }

  /// Updates the state based on a new measurement.
  double update(double measurement) {
    final kalmanGain = _covariance / (_covariance + _measurementNoise);
    _state = _state + kalmanGain * (measurement - _state);
    _covariance = (1 - kalmanGain) * _covariance;
    return _state;
  }
}

/// Calculates a smoothed velocity from a stream of Offset events using two Kalman filters (one for x, one for y).
///
/// This method provides more accurate and stable velocity estimates,
/// especially with noisy input data.
class KalmanVelocityCalculator {
  _KalmanFilter1D? _filterX;
  _KalmanFilter1D? _filterY;
  TimedOffset? _lastOffset;
  final _controller = StreamController<Velocity>();

  Stream<Velocity> get velocityStream => _controller.stream;

  KalmanVelocityCalculator();

  void addEvent(Offset offset) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastOffset == null) {
      _lastOffset = TimedOffset(offset, now);
      _filterX = _KalmanFilter1D(measurementNoise: 1.0, processNoise: 0.01);
      _filterY = _KalmanFilter1D(measurementNoise: 1.0, processNoise: 0.01);
      _controller.add(Velocity(x: 0.0, y: 0.0));
      return;
    }

    final double deltaX = offset.dx - _lastOffset!.offset.dx;
    final double deltaY = offset.dy - _lastOffset!.offset.dy;
    final int deltaTime = now - _lastOffset!.timestamp;

    if (deltaTime == 0) {
      _controller.add(Velocity(x: 0.0, y: 0.0));
      return;
    }

    final measuredVelocityX = deltaX / deltaTime;
    final measuredVelocityY = deltaY / deltaTime;

    _filterX!.predict();
    _filterY!.predict();

    final smoothedVelocityX = _filterX!.update(measuredVelocityX);
    final smoothedVelocityY = _filterY!.update(measuredVelocityY);

    _controller.add(Velocity(x: smoothedVelocityX, y: smoothedVelocityY));

    _lastOffset = TimedOffset(offset, now);
  }

  void dispose() {
    _controller.close();
  }
}

// ### How to use these classes
//
// 1.  **Instantiate:** Create an instance of the class you want to use. For most cases, `VelocityCalculator` is sufficient.
// ```dart
// final velocityCalculator = VelocityCalculator();
// ```
//
// 2.  **Add Events:** In your widget's gesture recognizer (e.g., `onPanUpdate` or `onMouseMove`), call the `addEvent` method with the new `Offset`.
// ```dart
// GestureDetector(
// onPanUpdate: (details) {
// velocityCalculator.addEvent(details.globalPosition);
// },
// child: Container(
// //...
// ),
// )
// ```
//
// 3.  **Listen to the Stream:** Use a `StreamBuilder` or a `StreamSubscription` to listen for the calculated `Velocity` values.
// ```dart
// StreamBuilder<Velocity>(
// stream: velocityCalculator.velocityStream,
// builder: (context, snapshot) {
// if (snapshot.hasData) {
// final velocity = snapshot.data!;
// return Text('Velocity: ${velocity.toString()}');
// }
// return Text('Waiting for movement...');
// },
// )
