import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/indoornotationmatcher.dart';
import 'package:test/test.dart';

void main() {
  group('IndoorNotationMatcher', () {
    // Test cases for parseLevelNumbers
    group('parseLevelNumbers', () {
      test('should parse single notation', () {
        expect(IndoorNotationMatcher.parseLevelNumbers('2'), equals([2]));
        expect(IndoorNotationMatcher.parseLevelNumbers('1.9'), equals([1]));
        expect(IndoorNotationMatcher.parseLevelNumbers('-1'), equals([-1]));
        expect(IndoorNotationMatcher.parseLevelNumbers('-1.1'), equals([-2]));
      });

      test('should parse multiple notation', () {
        expect(
            IndoorNotationMatcher.parseLevelNumbers('1;3;5'), equals([1, 3, 5]));
        expect(IndoorNotationMatcher.parseLevelNumbers('1.2;3.8;5'),
            equals([1, 3, 5]));
      });

      test('should parse simple range notation', () {
        expect(IndoorNotationMatcher.parseLevelNumbers('1-3'), equals([1, 2, 3]));
      });

      test('should parse negative range notation', () {
        expect(
            IndoorNotationMatcher.parseLevelNumbers('-2-1'), equals([-2, -1, 0, 1]));
      });

      test('should parse reversed range notation', () {
        expect(IndoorNotationMatcher.parseLevelNumbers('3-1'), equals([1, 2, 3]));
      });

      test('should parse decimal range notation', () {
        expect(
            IndoorNotationMatcher.parseLevelNumbers('1.1-3.9'), equals([1, 2, 3]));
      });

      test('should return null for invalid notation', () {
        expect(IndoorNotationMatcher.parseLevelNumbers('abc'), isNull);
        expect(IndoorNotationMatcher.parseLevelNumbers(''), isNull);
        expect(IndoorNotationMatcher.parseLevelNumbers('1;a;2'), isNull);
      });
    });

    // Test cases for matchesIndoorLevelNotation
    group('matchesIndoorLevelNotation', () {
      test('should match single level notation', () {
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('3', 3), isTrue);
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('3.2', 3), isTrue);
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('4', 3), isFalse);
      });

      test('should match multiple level notation', () {
        expect(
            IndoorNotationMatcher.matchesIndoorLevelNotation('1;3;5', 3), isTrue);
        expect(
            IndoorNotationMatcher.matchesIndoorLevelNotation('1;4;5', 3), isFalse);
      });

      test('should match range level notation', () {
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('1-5', 3), isTrue);
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('1-5', 1), isTrue);
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('1-5', 5), isTrue);
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('1-5', 6), isFalse);
      });

      test('should match reversed range level notation', () {
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('5-1', 3), isTrue);
      });

      test('should return false for invalid notation', () {
        expect(IndoorNotationMatcher.matchesIndoorLevelNotation('abc', 3), isFalse);
      });
    });

    // Test cases for getLevelValues
    group('getLevelValues', () {
      test('should return level tag value', () {
        final tags = TagCollection(tags: [const Tag('level', '1')]);
        expect(IndoorNotationMatcher.getLevelValues(tags), equals([1]));
      });

      test('should return repeat_on tag value', () {
        final tags = TagCollection(tags: [const Tag('repeat_on', '2')]);
        expect(IndoorNotationMatcher.getLevelValues(tags), equals([2]));
      });

      test('should merge level and repeat_on tags and remove duplicates', () {
        final tags = TagCollection(tags: [
          const Tag('level', '1;2'),
          const Tag('repeat_on', '2;3'),
        ]);
        expect(IndoorNotationMatcher.getLevelValues(tags), equals({1, 2, 3}));
      });

      test('should return null if no relevant tags exist', () {
        final tags = TagCollection(tags: [const Tag('name', 'test')]);
        expect(IndoorNotationMatcher.getLevelValues(tags), isNull);
      });

      test('should use cache on second call', () {
        final tags = TagCollection(tags: [
          const Tag('level', '1;2'),
          const Tag('repeat_on', '2;3'),
        ]);
        // First call populates the cache.
        final result1 = IndoorNotationMatcher.getLevelValues(tags);
        expect(result1, equals({1, 2, 3}));

        // Second call should return the same cached result instance.
        final result2 = IndoorNotationMatcher.getLevelValues(tags);
        expect(identical(result1, result2), isTrue);
      });
    });

    // Test cases for isOutdoorOrMatchesIndoorLevel
    group('isOutdoorOrMatchesIndoorLevel', () {
      test('should return true if no level tags exist', () {
        final tags = TagCollection(tags: [const Tag('name', 'test')]);
        expect(
            IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, 1), isTrue);
      });

      test('should return true if level matches', () {
        final tags = TagCollection(tags: [const Tag('level', '1-3')]);
        expect(
            IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, 2), isTrue);
      });

      test('should return false if level does not match', () {
        final tags = TagCollection(tags: [const Tag('level', '1-3')]);
        expect(
            IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, 4), isFalse);
      });
    });
  });
}
