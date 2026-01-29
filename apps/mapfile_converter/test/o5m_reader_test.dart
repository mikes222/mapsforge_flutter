import 'dart:io';

import 'package:mapfile_converter/o5m/o5m_reader.dart';
import 'package:test/test.dart';

void main() {
  test('O5mReader reads at least one node', () async {
    final fixture = File('test/fixtures/tiny.o5m');
    if (!fixture.existsSync()) {
      fail('Missing test fixture test/fixtures/tiny.o5m. Download it before running tests.');
    }

    final reader = await O5mReader.open(fixture.path);
    try {
      var nodes = 0;
      var ways = 0;
      var relations = 0;

      while (true) {
        final data = await reader.readNextBlobData();
        if (data == null) break;
        nodes += data.nodes.length;
        ways += data.ways.length;
        relations += data.relations.length;
      }

      expect(nodes, greaterThan(0));
      // Tiny extracts may or may not contain ways/relations.
      expect(ways, greaterThanOrEqualTo(0));
      expect(relations, greaterThanOrEqualTo(0));
    } finally {
      reader.dispose();
    }
  });
}
