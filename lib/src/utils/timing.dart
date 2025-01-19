import 'package:logging/logging.dart';

class Timing {
  final int _start;

  final bool active;

  final Logger log;

  final String? prefix;

  Timing({required this.log, this.active = true, this.prefix})
      : _start = DateTime.now().millisecondsSinceEpoch;

  void lap(int maxms, String text) {
    if (!active) return;
    int time = DateTime.now().millisecondsSinceEpoch;
    int diff = time - _start;
    if (diff > maxms) log.info("${prefix ?? ""}$diff ms: $text");
  }
}
