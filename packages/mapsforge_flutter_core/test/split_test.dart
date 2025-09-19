import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final Pattern splitPattern = ("|");

  test('split-test1', () {
    List<String> result = "sea|nosea".split(splitPattern);
    expect(result.length, 2);
    expect(result[0], 'sea');
  });

  test('split-test2', () {
    List<String> result = "*".split(splitPattern);
    expect(result.length, 1);
    expect(result[0], '*');
  });
}
