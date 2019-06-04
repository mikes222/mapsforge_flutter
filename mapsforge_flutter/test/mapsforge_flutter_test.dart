import 'package:flutter_test/flutter_test.dart';

import 'package:mapsforge_flutter/src/mapsforge_flutter.dart';

void main() {
  final Pattern SPLIT_PATTERN = ("|");

  test('split-test1', () {
    List<String> result = "sea|nosea".split(SPLIT_PATTERN);
    expect(result.length, 2);
    expect(result[0], 'sea');
  });

  test('split-test2', () {
    List<String> result = "*".split(SPLIT_PATTERN);
    expect(result.length, 1);
    expect(result[0], '*');
  });
}
