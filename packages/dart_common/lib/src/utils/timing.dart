import 'package:logging/logging.dart';

/// Performance timing utility for debugging and profiling code execution.
/// 
/// This class provides a simple way to measure execution time and log
/// performance warnings when operations exceed expected durations.
/// Only active in debug mode - all timing code is stripped in release builds.
/// 
/// Usage:
/// ```dart
/// final timing = Timing(log: logger, prefix: 'Operation: ');
/// // ... some work ...
/// timing.lap(100, 'intermediate step');
/// // ... more work ...
/// timing.done(200, 'complete operation');
/// ```
class Timing {
  /// Start time in milliseconds since epoch.
  final int _start;

  /// Whether timing measurements are active.
  /// When false, all timing operations are no-ops.
  final bool active;

  /// Logger instance for outputting timing information.
  final Logger log;

  /// Optional prefix for all timing log messages.
  final String? prefix;

  Timing({required this.log, this.active = true, this.prefix}) : _start = DateTime.now().millisecondsSinceEpoch;

  /// Logs a timing checkpoint if elapsed time exceeds the threshold.
  /// 
  /// Only executes in debug mode via assert(). The text string is still
  /// processed in release mode, so ensure it's fast to create.
  /// 
  /// [maxms] Maximum allowed milliseconds before logging
  /// [text] Description of the operation being timed
  void lap(int maxms, String text) {
    // this code will only executed in debug mode. See also https://stackoverflow.com/questions/56537718/what-does-assert-do-in-dart
    assert(() {
      if (!active) return true;
      int time = DateTime.now().millisecondsSinceEpoch;
      int diff = time - _start;
      if (diff > maxms) log.info("${prefix ?? ""}$diff ms: $text");
      return true;
    }());
  }

  /// Logs final timing result if elapsed time exceeds the threshold.
  /// 
  /// Similar to lap() but indicates completion of the timed operation.
  /// Only executes in debug mode via assert().
  /// 
  /// [maxms] Maximum allowed milliseconds before logging
  /// [text] Description of the completed operation
  void done(int maxms, String text) {
    // this code will only executed in debug mode. See also https://stackoverflow.com/questions/56537718/what-does-assert-do-in-dart
    assert(() {
      if (!active) return true;
      int time = DateTime.now().millisecondsSinceEpoch;
      int diff = time - _start;
      if (diff > maxms) log.info("${prefix ?? ""}DONE $diff ms: $text");
      return true;
    }());
  }
}
