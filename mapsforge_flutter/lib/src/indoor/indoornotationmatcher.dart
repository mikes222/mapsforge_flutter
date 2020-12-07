import 'dart:math';
import '../model/tag.dart';

class IndoorNotationMatcher {
  // match single value : 1 or -1.5
  static final RegExp _matchSingleNotation = new RegExp(r"^-?\d+(\.\d+)?$");
  // match multiple values notation : 1;3;4 or 1.4;-4;2
  static final RegExp _matchMultipleNotation = new RegExp(r"^(-?\d+(\.\d+)?)(;-?\d+(\.\d+)?)+$");
  // match value range notation : 1-2 or -1--5
  static final RegExp _matchRangeNotation = new RegExp(r"^-?\d+(\.\d+)?--?\d+(\.\d+)?$");

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
   * Returns true if the given level matches the given level tag notation
   * otherwise false
   */
  static bool matchesIndoorLevelNotation (String levelTagValue, double level) {
    if (matchesSingleNotation(levelTagValue)) {
      final double levelValue = double.tryParse(levelTagValue);
      return (levelValue == level);
    }
    else if (matchesMultipleNotation(levelTagValue)) {
      // split on ";" and convert values to double
      final Iterable <double> levelValues = levelTagValue.split(";").map(double.tryParse);
      // check if at least one value matches the current level
      return levelValues.any((levelValue) => levelValue == level);
    }
    else if (matchesRangeNotation(levelTagValue)) {
      // split on "-" if number precedes and convert to double
      final Iterable <double> levelRange = levelTagValue.split(RegExp(r"(?<=\d)-")).map(double.tryParse);
      // separate into max and min value
      double lowerLevelValue = levelRange.reduce(min);
      double upperLevelValue = levelRange.reduce(max);
      // if level is in range return true else false
      return (lowerLevelValue <= level && upperLevelValue >= level);
    }
    return false;
  }
  
  /* 
   * Returns the level or repeat_on value string of a given tag list
   * null if no key is found
   */
  static String getLevelValue(List<Tag> tags) {
    // search for level key
    Tag levelTag = tags.firstWhere((Tag element) {
      return element.key == "level";
    }, orElse: () => null);

    // if no level key exists search for repeat_on key and treat its value as the level
    if (levelTag == null) levelTag = tags.firstWhere((Tag element) {
      return element.key == "repeat_on";
    }, orElse: () => null);

    return levelTag?.value;
  }

  /*
   * Returns the level ref value string of a given tag list
   * null if no key is found
   */
  static String getLevelRefValue(List<Tag> tags) {
    // search for level key
    Tag levelRefTag = tags.firstWhere((Tag element) {
      return element.key == "level:ref";
    }, orElse: () => null);

    return levelRefTag?.value;
  }

  /*
   * Returns true if either the given level matches the given tags
   * or the given tags do not contain any indoor level key
   * or the given indoor level is null
   * otherwise false
   */
  static bool isOutdoorOrMatchesIndoorLevel (List<Tag> tags, double level) {
    String levelValue = getLevelValue(tags);
    // return true if no level tag exists
    if (levelValue == null || level == null) return true;
    return matchesIndoorLevelNotation(levelValue, level);
  }
}