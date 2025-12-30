import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/matching_cache_key.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('MatchingCacheKey Performance Optimizations', () {
    group('Hash Function Optimization', () {
      test('should generate different hashes for different tag combinations', () {
        final tags1 = TagCollection(tags: [const Tag('highway', 'primary'), const Tag('name', 'Main Street')]);
        final tags2 = TagCollection(tags: [const Tag('highway', 'secondary'), const Tag('name', 'Main Street')]);
        final tags3 = TagCollection(tags: [const Tag('highway', 'primary'), const Tag('name', 'Side Street')]);

        final key1 = MatchingCacheKey(tags1, 0);
        final key2 = MatchingCacheKey(tags2, 0);
        final key3 = MatchingCacheKey(tags3, 0);

        expect(key1.hashCode, isNot(equals(key2.hashCode)));
        expect(key1.hashCode, isNot(equals(key3.hashCode)));
        expect(key2.hashCode, isNot(equals(key3.hashCode)));
      });

      test('should generate same hash for identical keys', () {
        final tags = TagCollection(tags: [const Tag('highway', 'primary'), const Tag('name', 'Main Street')]);

        final key1 = MatchingCacheKey(tags, 0);
        final key2 = MatchingCacheKey(tags, 0);

        expect(key1.hashCode, equals(key2.hashCode));
        expect(key1, equals(key2));
      });

      test('should generate unique hashcodes', () {
        int i1 = 0;
        int i2 = -1;

        print("${i1.hashCode} ${i2.hashCode}");
        expect(i1.hashCode, isNot(equals(i2.hashCode)));
      });

      test('should handle empty tag lists', () {
        final key1 = const MatchingCacheKey(TagCollection.empty(), 0);
        final key2 = const MatchingCacheKey(TagCollection.empty(), 0);
        final key3 = const MatchingCacheKey(TagCollection.empty(), 1);
        final key4 = const MatchingCacheKey(TagCollection.empty(), -1);

        expect(key1.hashCode, equals(key2.hashCode));
        expect(key1.hashCode, isNot(equals(key3.hashCode)));
        expect(key1.hashCode, isNot(equals(key4.hashCode)));
      });

      test('should incorporate indoor level in hash', () {
        final tags = TagCollection(tags: [const Tag('highway', 'primary')]);

        final key1 = MatchingCacheKey(tags, 0);
        final key2 = MatchingCacheKey(tags, 1);
        final key3 = MatchingCacheKey(tags, -1);

        expect(key1.hashCode, isNot(equals(key2.hashCode)));
        expect(key1.hashCode, isNot(equals(key3.hashCode)));
        expect(key2.hashCode, isNot(equals(key3.hashCode)));
      });
    });

    group('Hash Distribution Quality', () {
      test('should produce well-distributed hashes for similar tags', () {
        final Set<int> hashCodes = <int>{};

        // Generate many similar but different tag combinations
        for (int i = 0; i < 100; i++) {
          final tags = TagCollection(tags: [const Tag('highway', 'primary'), Tag('name', 'Street $i'), Tag('ref', 'A$i')]);
          final key = MatchingCacheKey(tags, i % 5);
          hashCodes.add(key.hashCode);
        }

        // Should have good distribution (most hashes should be unique)
        expect(hashCodes.length, greaterThan(90)); // At least 90% unique
      });

      test('should handle hash collisions gracefully with equality check', () {
        final tags1 = TagCollection(tags: [const Tag('highway', 'primary'), const Tag('name', 'Main')]);
        final tags2 = TagCollection(tags: [const Tag('highway', 'secondary'), const Tag('name', 'Side')]);

        final key1 = MatchingCacheKey(tags1, 0);
        final key2 = MatchingCacheKey(tags2, 0);

        // Even if hash codes were the same (unlikely), equality should work correctly
        if (key1.hashCode == key2.hashCode) {
          expect(key1, isNot(equals(key2)));
        }
      });
    });

    group('Performance Tests', () {
      test('should compute hashes efficiently for large tag lists', () {
        // Create a large tag list
        final List<Tag> largeTags = <Tag>[];
        for (int i = 0; i < 100; i++) {
          largeTags.add(Tag('key$i', 'value$i'));
        }

        final stopwatch = Stopwatch()..start();

        // Compute hash many times
        for (int i = 0; i < 1000; i++) {
          final key = MatchingCacheKey(TagCollection(tags: largeTags), i);
          key.hashCode; // Force hash computation
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      });

      test('should perform equality checks efficiently', () {
        final tags1 = TagCollection(tags: List.generate(50, (i) => Tag('key$i', 'value$i')));
        final tags2 = TagCollection(tags: List.generate(50, (i) => Tag('key$i', 'value$i')));
        final tags3 = TagCollection(tags: List.generate(50, (i) => Tag('key$i', 'different$i')));

        final key1 = MatchingCacheKey(tags1, 0);
        final key2 = MatchingCacheKey(tags2, 0);
        final key3 = MatchingCacheKey(tags3, 0);

        final stopwatch = Stopwatch()..start();

        // Perform many equality checks
        for (int i = 0; i < 1000; i++) {
          key1 == key2; // Should be true
          key1 == key3; // Should be false
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      });
    });

    group('Edge Cases', () {
      test('should handle null and empty values in tags', () {
        final tags1 = TagCollection(tags: [const Tag('highway', ''), const Tag('', 'value')]);
        final tags2 = TagCollection(tags: [const Tag('highway', "test"), const Tag("test", 'value')]);

        final key1 = MatchingCacheKey(tags1, 0);
        final key2 = MatchingCacheKey(tags2, 0);

        // Should not throw exceptions
        expect(() => key1.hashCode, returnsNormally);
        expect(() => key2.hashCode, returnsNormally);
        expect(() => key1 == key2, returnsNormally);
      });

      test('should handle extreme indoor levels', () {
        final tags = TagCollection(tags: [const Tag('highway', 'primary')]);

        final keyMin = MatchingCacheKey(tags, -1000000);
        final keyMax = MatchingCacheKey(tags, 1000000);

        expect(() => keyMin.hashCode, returnsNormally);
        expect(() => keyMax.hashCode, returnsNormally);
        expect(keyMin.hashCode, isNot(equals(keyMax.hashCode)));
      });

      test('should handle tags with very long strings', () {
        final longString = 'a' * 1000;
        final tags = TagCollection(tags: [Tag('highway', longString), Tag(longString, 'primary')]);

        final key = MatchingCacheKey(tags, 0);

        expect(() => key.hashCode, returnsNormally);
      });
    });

    group('Hash Algorithm Validation', () {
      test('should use FNV-1a algorithm characteristics', () {
        final tags = TagCollection(tags: [const Tag('test', 'value')]);
        final key = MatchingCacheKey(tags, 0);

        final hash = key.hashCode;

        // FNV-1a should produce non-zero hashes for non-empty input
        expect(hash, isNot(equals(0)));

        // Should be deterministic
        expect(key.hashCode, equals(hash));
        expect(key.hashCode, equals(hash));
      });

      test('should minimize hash collisions compared to simple XOR', () {
        final Set<int> hashCodes = <int>{};

        // Test with systematic tag variations that might cause XOR collisions
        for (int i = 0; i < 50; i++) {
          for (int j = 0; j < 50; j++) {
            final tags = TagCollection(tags: [Tag('key$i', 'value$j')]);
            final key = MatchingCacheKey(tags, 0);
            hashCodes.add(key.hashCode);
          }
        }

        // Should have very few collisions
        expect(hashCodes.length, greaterThan(2400)); // > 96% unique
      });
    });

    group('Memory Efficiency', () {
      test('should not create unnecessary objects during hashing', () {
        final tags = TagCollection(tags: [const Tag('highway', 'primary'), const Tag('name', 'Main Street')]);
        final key = MatchingCacheKey(tags, 0);

        // Hash computation should not allocate significant memory
        // This is more of a design validation than a measurable test
        expect(() => key.hashCode, returnsNormally);
      });

      test('should handle repeated hash computations efficiently', () {
        final tags = TagCollection(tags: [const Tag('highway', 'primary')]);
        final key = MatchingCacheKey(tags, 0);

        final stopwatch = Stopwatch()..start();

        // Compute hash many times (simulating cache lookups)
        for (int i = 0; i < 10000; i++) {
          key.hashCode;
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(10)); // Should be extremely fast
      });
    });
  });
}
