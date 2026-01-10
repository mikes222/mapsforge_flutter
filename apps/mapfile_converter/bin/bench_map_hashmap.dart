import 'dart:collection';
import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

typedef LatLonMap = Map<int, LatLong>;

enum MapKind { map, hashMap }

class BenchResult {
  final String operation;
  final MapKind kind;
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

LatLonMap _createMap(MapKind kind) {
  switch (kind) {
    case MapKind.map:
      return <int, LatLong>{};
    case MapKind.hashMap:
      return HashMap<int, LatLong>();
  }
}

BenchResult _time(
  String operation,
  MapKind kind,
  int n,
  int iterations,
  void Function() fn,
) {
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
  buf.writeln('| N | Map type | Operation | total ms | iters | µs/op |');
  buf.writeln('|---:|---|---|---:|---:|---:|');
  for (final r in results) {
    final mapType = r.kind == MapKind.map ? 'Map(LinkedHashMap)' : 'HashMap';
    buf.writeln(
      '| ${r.n} | $mapType | ${r.operation} | ${r.ms.toStringAsFixed(2)} | ${r.iterations} | ${r.usPerOp.toStringAsFixed(3)} |',
    );
  }
  print(buf.toString());
}

Future<void> main(List<String> args) async {
  final sizes = <int>[100, 10000, 1000000];

  final rng = Random(1);
  final results = <BenchResult>[];

  for (final n in sizes) {
    final keys = List<int>.generate(n, (i) => i, growable: false);
    final values = List<LatLong>.generate(n, (_) => _randomLatLong(rng), growable: false);

    for (final kind in [MapKind.map, MapKind.hashMap]) {
      LatLonMap m;

      m = _createMap(kind);
      results.add(
        _time('[_collection[id] = value] build', kind, n, n, () {
          final i = m.length;
          m[keys[i]] = values[i];
        }),
      );

      results.add(_time('[_collection.length]', kind, n, 200000, () {
        final _ = m.length;
      }));

      results.add(_time('[_collection.containsKey(id)] hit', kind, n, 200000, () {
        final _ = m.containsKey(keys[n ~/ 2]);
      }));

      results.add(_time('[_collection.containsKey(id)] miss', kind, n, 200000, () {
        final _ = m.containsKey(-1);
      }));

      results.add(_time('[for (final e in entries)] iterate', kind, n, 1, () {
        int acc = 0;
        for (final e in m.entries) {
          acc ^= e.key;
        }
        if (acc == 42) {
          throw StateError('unreachable');
        }
      }));

      results.add(_time('[_collection.forEach((k,v))] iterate', kind, n, 1, () {
        int acc = 0;
        m.forEach((k, v) {
          acc ^= k;
        });
        if (acc == 42) {
          throw StateError('unreachable');
        }
      }));

      results.add(_time('[_collection.values] iterate', kind, n, 1, () {
        int acc = 0;
        for (final v in m.values) {
          acc ^= v.latitude.floor();
        }
        if (acc == 42) {
          throw StateError('unreachable');
        }
      }));

      results.add(_time('[_collection.keys] iterate', kind, n, 1, () {
        int acc = 0;
        for (final k in m.keys) {
          acc ^= k;
        }
        if (acc == 42) {
          throw StateError('unreachable');
        }
      }));

      results.add(_time('[_collection.remove(id)] hit', kind, n, 10000, () {
        final key = keys[(m.length - 1) & (n - 1)];
        final removed = m.remove(key);
        if (removed == null) {
          m[key] = values[0];
        }
        m[key] = values[0];
      }));

      results.add(_time('[_collection.remove(id)] miss', kind, n, 10000, () {
        m.remove(-1);
      }));

      results.add(_time('[_collection.removeWhere]', kind, n, 1, () {
        final copy = _createMap(kind);
        for (int i = 0; i < n; i++) {
          copy[keys[i]] = values[i];
        }
        copy.removeWhere((k, v) => (k & 1) == 0);
        if (copy.length != (n / 2).ceil()) {
          throw StateError('unexpected size');
        }
      }));
    }
  }

  _printTable(results);
}
