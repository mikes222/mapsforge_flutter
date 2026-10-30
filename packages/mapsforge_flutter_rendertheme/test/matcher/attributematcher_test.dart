import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:test/test.dart';

void main() {
  group('AttributeMatcher cache', () {
    test('returns the same KeyMatcher for equal key lists', () {
      // RuleBuilder hands over a fresh list per rule (keys.split("|")), so the
      // cache must hit on content, not on list identity.
      AttributeMatcher first = AttributeMatcher.getKeyMatcher([
        "highway",
        "railway",
      ]);
      AttributeMatcher second = AttributeMatcher.getKeyMatcher([
        "highway",
        "railway",
      ]);
      expect(identical(first, second), isTrue);
    });

    test('returns the same ValueMatcher for equal value lists', () {
      AttributeMatcher first = AttributeMatcher.getValueMatcher([
        "path",
        "track",
      ]);
      AttributeMatcher second = AttributeMatcher.getValueMatcher([
        "path",
        "track",
      ]);
      expect(identical(first, second), isTrue);
    });

    test('distinguishes different lists', () {
      AttributeMatcher a = AttributeMatcher.getKeyMatcher(["natural"]);
      AttributeMatcher b = AttributeMatcher.getKeyMatcher([
        "natural",
        "landuse",
      ]);
      expect(identical(a, b), isFalse);
    });

    test('cache does not grow when the same lists are requested again', () {
      int keys = AttributeMatcher.MATCHERS_CACHE_KEY.length;
      int values = AttributeMatcher.MATCHERS_CACHE_VALUE.length;
      for (int i = 0; i < 10; ++i) {
        AttributeMatcher.getKeyMatcher(["highway", "railway"]);
        AttributeMatcher.getValueMatcher(["path", "track"]);
      }
      expect(AttributeMatcher.MATCHERS_CACHE_KEY.length, keys);
      expect(AttributeMatcher.MATCHERS_CACHE_VALUE.length, values);
    });

    test('wildcard is not cached', () {
      expect(AttributeMatcher.getKeyMatcher(["*"]), isA<AnyMatcher>());
      expect(AttributeMatcher.getValueMatcher(["*"]), isA<AnyMatcher>());
    });
  });
}
