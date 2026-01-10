import 'dart:collection';
import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

LatLong _randomLatLong(Random rng) {
  final lat = rng.nextDouble() * 180.0 - 90.0;
  final lon = rng.nextDouble() * 360.0 - 180.0;
  return LatLong(lat, lon);
}

void _warmup() {
  // Small warmup to reduce JIT noise.
  final q = ListQueue<int>();
  for (int i = 0; i < 10000; i++) {
    q.add(i);
  }
  q.removeWhere((e) => (e & 1) == 0);
}

double _timeMs(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsedMicroseconds / 1000.0;
}

Future<void> main(List<String> args) async {
  const n = 1000000;
  final rng = Random(1);

  // Pre-generate values and a deterministic predicate.
  final values = List<LatLong>.generate(n, (_) => _randomLatLong(rng), growable: false);
  bool test(LatLong e) => (e.latitude.floor() & 1) == 0;

  _warmup();

  // Procedure A: built-in removeWhere
  {
    final q = ListQueue<LatLong>.from(values);
    final ms = _timeMs(() {
      q.removeWhere(test);
    });
    print('Queue(ListQueue) removeWhere(): ${ms.toStringAsFixed(2)} ms; remaining=${q.length}');
  }

  // Procedure B: manual filter/rebuild
  {
    final q = ListQueue<LatLong>.from(values);
    final ms = _timeMs(() {
      final newEntries = ListQueue<LatLong>();
      for (final e in q) {
        if (!test(e)) {
          newEntries.add(e);
        }
      }
      q
        ..clear()
        ..addAll(newEntries);
    });
    print('Queue(ListQueue) manual filter+rebuild: ${ms.toStringAsFixed(2)} ms; remaining=${q.length}');
  }
}
