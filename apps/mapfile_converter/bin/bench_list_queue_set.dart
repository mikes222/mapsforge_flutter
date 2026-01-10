import 'dart:collection';
import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

enum CollectionKind { list, queue, set }

typedef TestPredicate<T> = bool Function(T);

class BenchResult {
  final String operation;
  final CollectionKind kind;
  final int n;
  final int iterations;
  final double ms;

  BenchResult({
    required this.operation,
    required this.kind,
    required this.n,
    required this.iterations,
    required this.ms,
  });

  double get usPerOp => (ms * 1000.0) / iterations;
}

LatLong _randomLatLong(Random rng) {
  final lat = rng.nextDouble() * 180.0 - 90.0;
  final lon = rng.nextDouble() * 360.0 - 180.0;
  return LatLong(lat, lon);
}

BenchResult _time(String operation, CollectionKind kind, int n, int iterations, void Function() fn) {
  final sw = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  return BenchResult(
    operation: operation,
    kind: kind,
    n: n,
    iterations: iterations,
    ms: sw.elapsedMicroseconds / 1000.0,
  );
}

void _printTable(List<BenchResult> results) {
  final buf = StringBuffer();
  buf.writeln('| N | Collection | Operation | total ms | iters | µs/op |');
  buf.writeln('|---:|---|---|---:|---:|---:|');
  for (final r in results) {
    final coll = switch (r.kind) {
      CollectionKind.list => 'List',
      CollectionKind.queue => 'Queue(ListQueue)',
      CollectionKind.set => 'Set(HashSet)',
    };
    buf.writeln(
      '| ${r.n} | $coll | ${r.operation} | ${r.ms.toStringAsFixed(2)} | ${r.iterations} | ${r.usPerOp.toStringAsFixed(3)} |',
    );
  }
  print(buf.toString());
}

Future<void> main(List<String> args) async {
  final sizes = <int>[100, 10000, 1000000];
  final rng = Random(1);

  final results = <BenchResult>[];

  for (final n in sizes) {
    // Pre-generate values so RNG cost doesn't dominate.
    final values = List<LatLong>.generate(n, (_) => _randomLatLong(rng), growable: false);

    // LIST
    {
      final list = <LatLong>[];
      results.add(_time('[_entries.add] build', CollectionKind.list, n, n, () {
        list.add(values[list.length]);
      }));

      results.add(_time('[_entries.length]', CollectionKind.list, n, 200000, () {
        final _ = list.length;
      }));

      results.add(_time('[for (var entry in _entries)] iterate', CollectionKind.list, n, 1, () {
        int acc = 0;
        for (final e in list) {
          acc ^= e.latitude.floor();
        }
        if (acc == 42) throw StateError('unreachable');
      }));

      // removeWhere is destructive; measure on a fresh copy
      results.add(_time('[_entries.removeWhere(test)]', CollectionKind.list, n, 1, () {
        final copy = List<LatLong>.from(list);
        copy.removeWhere((e) => (e.latitude.floor() & 1) == 0);
        if (copy.isEmpty) {
          // avoid DCE
          throw StateError('unexpected empty');
        }
      }));

      // removeFirst not applicable for List directly
      results.add(_time('[_entries.removeFirst()] (n/a)', CollectionKind.list, n, 1, () {}));
    }

    // QUEUE (ListQueue)
    {
      final q = ListQueue<LatLong>();
      results.add(_time('[_entries.add] build', CollectionKind.queue, n, n, () {
        q.add(values[q.length]);
      }));

      results.add(_time('[_entries.length]', CollectionKind.queue, n, 200000, () {
        final _ = q.length;
      }));

      results.add(_time('[for (var entry in _entries)] iterate', CollectionKind.queue, n, 1, () {
        int acc = 0;
        for (final e in q) {
          acc ^= e.latitude.floor();
        }
        if (acc == 42) throw StateError('unreachable');
      }));

      results.add(_time('[_entries.removeWhere(test)]', CollectionKind.queue, n, 1, () {
        final copy = ListQueue<LatLong>.from(q);
        copy.removeWhere((e) => (e.latitude.floor() & 1) == 0);
        if (copy.isEmpty) {
          throw StateError('unexpected empty');
        }
      }));

      // removeFirst is destructive; measure many ops on a fresh copy each time.
      // Here we measure removing 10k items (or n if smaller) to reduce noise.
      final removeOps = min(10000, n);
      results.add(_time('[_entries.removeFirst()] $removeOps ops', CollectionKind.queue, n, 1, () {
        final copy = ListQueue<LatLong>.from(q);
        for (int i = 0; i < removeOps; i++) {
          copy.removeFirst();
        }
      }));
    }

    // SET (HashSet)
    {
      final s = HashSet<LatLong>();
      results.add(_time('[_entries.add] build', CollectionKind.set, n, n, () {
        // Ensure unique-ish objects: values are distinct objects, so should be ok.
        s.add(values[s.length]);
      }));

      results.add(_time('[_entries.length]', CollectionKind.set, n, 200000, () {
        final _ = s.length;
      }));

      results.add(_time('[for (var entry in _entries)] iterate', CollectionKind.set, n, 1, () {
        int acc = 0;
        for (final e in s) {
          acc ^= e.latitude.floor();
        }
        if (acc == 42) throw StateError('unreachable');
      }));

      results.add(_time('[_entries.removeWhere(test)]', CollectionKind.set, n, 1, () {
        final copy = HashSet<LatLong>.from(s);
        copy.removeWhere((e) => (e.latitude.floor() & 1) == 0);
        if (copy.isEmpty) {
          throw StateError('unexpected empty');
        }
      }));

      results.add(_time('[_entries.removeFirst()] (n/a)', CollectionKind.set, n, 1, () {}));
    }
  }

  _printTable(results);
}
