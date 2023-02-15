import 'dart:math';
import '../model/tag.dart';
import 'package:collection/collection.dart' show IterableExtension;

class IndoorNotationMatcher {
  // match single value : 1 or -1.5
  static final RegExp _matchSingleNotation = new RegExp(r"^-?\d+(\.\d+)?$");

  // match multiple values notation : 1;3;4 or 1.4;-4;2
  static final RegExp _matchMultipleNotation =
      new RegExp(r"^(-?\d+(\.\d+)?)(;-?\d+(\.\d+)?)+$");

  // match value range notation : 1-2 or -1--5
  static final RegExp _matchRangeNotation =
      new RegExp(r"^-?\d+(\.\d+)?--?\d+(\.\d+)?$");

  static bool matchesSingleNotation(String levelTagValue) {
    return _matchSingleNotation.hasMatch(levelTagValue);
  }

  static bool matchesMultipleNotation(String levelTagValue) {
    return _matchMultipleNotation.hasMatch(levelTagValue);
  }

  static bool matchesRangeNotation(String levelTagValue) {
    return _matchRangeNotation.hasMatch(levelTagValue);
  }

  /*
   * Returns int or null if no number could be parsed
   * Decimal numbers are round down to next int
   */
  static int? parseLevelNumber(String levelTagValue) {
    return double.tryParse(levelTagValue)?.floor();
  }

  /*
   * Returns all level values as integer in an Iterable
   * Decimal numbers are round down to next int
   * Range values are converted to multiple values
   * Returns null if the String couldn't be parsed successfully
   */
  static Iterable<int>? parseLevelNumbers(String levelTagValue) {
    if (IndoorNotationMatcher.matchesSingleNotation(levelTagValue)) {
      return [IndoorNotationMatcher.parseLevelNumber(levelTagValue)]
          .where((element) => element != null)
          .map((e) => e as int)
          .toList();
    } else if (IndoorNotationMatcher.matchesMultipleNotation(levelTagValue)) {
      // split on ";" and convert values to int
      return levelTagValue
          .split(";")
          .map(IndoorNotationMatcher.parseLevelNumber)
          .where((element) => element != null)
          .map((e) => e as int)
          .toList();
    } else if (IndoorNotationMatcher.matchesRangeNotation(levelTagValue)) {
      // split on "-" if number precedes and convert to int
      Iterable<int> levelRange = levelTagValue
          .split(RegExp(r"(?<=\d)-"))
          .map(IndoorNotationMatcher.parseLevelNumber)
          .where((element) => element != null)
          .map((e) => e as int)
          .toList();
      int lowerLevelValue = levelRange.reduce(min);
      int upperLevelValue = levelRange.reduce(max);
      int levelCount = (lowerLevelValue - upperLevelValue).abs() + 1;
      return Iterable.generate(levelCount, (i) => lowerLevelValue + i);
    }
    return null;
  }

  /*
   * Returns true if the given level matches the given level tag notation
   * otherwise false
   */
  static bool matchesIndoorLevelNotation(String levelTagValue, int level) {
    if (matchesSingleNotation(levelTagValue)) {
      int? levelValue = parseLevelNumber(levelTagValue);
      return (levelValue == level);
    } else if (matchesMultipleNotation(levelTagValue)) {
      // split on ";" and convert values to int
      Iterable<int?> levelValues =
          levelTagValue.split(";").map(parseLevelNumber);
      // check if at least one value matches the current level
      return levelValues.contains(level);
    } else if (matchesRangeNotation(levelTagValue)) {
      // split on "-" if number precedes and convert to int
      Iterable<int?> levelRange =
          levelTagValue.split(RegExp(r"(?<=\d)-")).map(parseLevelNumber);
      List<int> levelRange2 = levelRange
          .where((element) => element != null)
          .map((e) => e as int)
          .toList();
      // separate into max and min value
      int lowerLevelValue = levelRange2.reduce(min);
      int upperLevelValue = levelRange2.reduce(max);
      // if level is in range return true else false
      return (lowerLevelValue <= level && upperLevelValue >= level);
    }
    return false;
  }

  /*
   * Returns the level or repeat_on value string of a given tag list
   * If both tags are set their values are merged
   * null if no key is found
   */
  static String? getLevelValue(List<Tag> tags) {
    // search for level key
    final Tag? levelTag = tags.firstWhereOrNull((Tag element) {
      return element.key == "level";
    });

    // search for repeat_on key
    final Tag? repeatOnTag = tags.firstWhereOrNull((Tag element) {
      return element.key == "repeat_on";
    });

    // if both tags exist then merge their values together
    // https://wiki.openstreetmap.org/wiki/Talk:Simple_Indoor_Tagging#repeat_on_and_level_on_one_object
    if (levelTag != null && repeatOnTag != null) {
      final Iterable<int?>? levelValues = parseLevelNumbers(levelTag.value!);
      final Iterable<int?>? repeatOnValues =
          parseLevelNumbers(repeatOnTag.value!);
      // merge them in a Set to automatically remove duplicates
      return {...?levelValues, ...?repeatOnValues}.join(";");
    }
    // if no level tag exists use the repeat_on value as the level value else return null
    return levelTag?.value ?? repeatOnTag?.value;
  }

  /*
   * Returns the level ref value string of a given tag list
   * null if no key is found
   */
  static String? getLevelRefValue(List<Tag> tags) {
    // search for level key
    Tag? levelRefTag = tags.firstWhereOrNull((Tag element) {
      return element.key == "level:ref";
    });

    return levelRefTag?.value;
  }

  /*
   * Returns true if either the given level matches the given tags
   * or the given tags do not contain any indoor level key
   * or the given indoor level is null
   * otherwise false
   */
  static bool isOutdoorOrMatchesIndoorLevel(List<Tag> tags, int level) {
    String? levelValue = getLevelValue(tags);
    // return true if no level tag exists
    if (levelValue == null) return true;
    return matchesIndoorLevelNotation(levelValue, level);
  }
}
