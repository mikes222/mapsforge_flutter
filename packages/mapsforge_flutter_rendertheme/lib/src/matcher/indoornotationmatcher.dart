import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:mapsforge_flutter_core/model.dart';

class IndoorNotationMatcher {
  // Use an Expando to associate cached level data with TagCollection instances.
  // This avoids modifying the TagCollection class and works with const instances.
  // Expando does not support nullable types, so we use a sentinel for null.
  static final Expando<Object> _levelCache = Expando('indoorLevels');
  static const _nullSentinel = Object();

  /// Returns an int from a string, or null if no number could be parsed.
  /// Decimal numbers are rounded down to the next int.
  static int? _parseLevelNumber(String levelTagValue) {
    return double.tryParse(levelTagValue)?.floor();
  }

  /// Returns all level values as integers in an Iterable.
  ///
  /// Decimal numbers are rounded down to the next int.
  /// Range values are converted to multiple values.
  /// Returns null if the String couldn't be parsed successfully.
  static Iterable<int>? parseLevelNumbers(String levelTagValue) {
    if (levelTagValue.isEmpty) return null;
    final parts = levelTagValue.split(';');
    if (parts.length > 1) {
      // Multiple values notation: 1;3;4 or 1.4;-4;2
      final parsed = parts.map(_parseLevelNumber).toList();
      if (parsed.contains(null)) {
        return null; // If any part is invalid, the whole string is invalid
      }
      return parsed.map((e) => e as int).toList();
    } else {
      // Try to parse as a range or a single value
      final rangeParts = levelTagValue.split(RegExp(r'(?<=\d)-'));
      if (rangeParts.length == 2) {
        // Range notation: 1-2 or -1--5
        final start = _parseLevelNumber(rangeParts[0]);
        final end = _parseLevelNumber(rangeParts[1]);
        if (start != null && end != null) {
          final lower = min(start, end);
          final upper = max(start, end);
          return Iterable.generate(upper - lower + 1, (i) => lower + i);
        }
      } else {
        // Single value notation: 1 or -1.5
        final level = _parseLevelNumber(levelTagValue);
        if (level != null) {
          return [level];
        }
      }
    }
    return null;
  }

  /// Returns true if the given level matches the given level tag notation, otherwise false.
  static bool matchesIndoorLevelNotation(String levelTagValue, int level) {
    final levels = parseLevelNumbers(levelTagValue);
    return levels?.contains(level) ?? false;
  }

  /// Returns the parsed level or repeat_on values from a given tag list.
  ///
  /// If both 'level' and 'repeat_on' tags are set, their values are merged.
  /// The result is cached for subsequent calls.
  /// Returns null if no relevant key is found.
  static Iterable<int>? getLevelValues(TagCollection tags) {
    final cached = _levelCache[tags];
    if (cached != null) {
      return cached == _nullSentinel ? null : cached as Iterable<int>;
    }

    final String? levelTag = tags.getTag("level");
    final String? repeatOnTag = tags.getTag("repeat_on");

    Iterable<int>? levelValues;
    if (levelTag != null) {
      levelValues = parseLevelNumbers(levelTag);
    }

    Iterable<int>? repeatOnValues;
    if (repeatOnTag != null) {
      repeatOnValues = parseLevelNumbers(repeatOnTag);
    }

    Iterable<int>? result;
    if (levelValues != null && repeatOnValues != null) {
      // Merge them in a Set to automatically remove duplicates
      result = {...levelValues, ...repeatOnValues};
    } else {
      result = levelValues ?? repeatOnValues;
    }

    // Cache the result, using the sentinel for null.
    _levelCache[tags] = result ?? _nullSentinel;
    return result;
  }

  /// Returns the level ref value string of a given tag list, or null if no key is found.
  static String? getLevelRefValue(List<Tag> tags) {
    return tags
        .firstWhereOrNull((Tag element) => element.key == "level:ref")
        ?.value;
  }

  /// Returns true if the given tags do not contain any indoor level key, or if the given level matches.
  static bool isOutdoorOrMatchesIndoorLevel(TagCollection tags, int level) {
    final levelValues = getLevelValues(tags);
    // Return true if no level tag exists.
    if (levelValues == null) return true;
    // Otherwise, check if the level is contained in the parsed values.
    return levelValues.contains(level);
  }
}
