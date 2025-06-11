import 'package:logging/logging.dart';

class Timing {
  final int _start;

  final bool active;

  final Logger log;

  final String? prefix;

  Timing({required this.log, this.active = true, this.prefix}) : _start = DateTime.now().millisecondsSinceEpoch;

  /// Prints an info if the timing exceeds the given number of milliseconds. This code will not be executed in release mode however
  /// the given string will be concatenated/processed anyway regardless of timing or debug/release mode. Thus make sure it is fast to create the string.
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
