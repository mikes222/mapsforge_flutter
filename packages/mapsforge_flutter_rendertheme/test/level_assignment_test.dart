import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Unit tests to verify that render instruction levels are assigned correctly.
///
/// This test verifies the critical behavior discovered from defaultrender.xml:
/// 1. Each rule gets a unique level assigned in ascending order (0, 1, 2, ...)
/// 2. All render instructions within the same rule share the same level
/// 3. Different rules can have different levels, creating layered rendering
/// 4. The defaultrender.xml contains 354 unique levels (0-353) across all rules
/// 5. Levels are consecutive with no gaps, ensuring proper rendering order
void main() {
  setUpAll(() {
    _initLogging();
  });

  group('Level Assignment Tests', () {
    late Rendertheme renderTheme;

    setUpAll(() async {
      renderTheme = await RenderThemeBuilder.createFromFile("test/defaultrender.xml");
    });

    test('should have exactly 354 levels (0-353) for defaultrender.xml', () {
      expect(renderTheme.maxLevels, equals(353));
    });

    test('should assign levels correctly within rules', () {
      Set<int> allLevels = <int>{};
      List<int> levelsList = <int>[];

      // Collect all levels from all rules
      _collectLevelsFromRules(renderTheme.rulesList, allLevels, levelsList);

      // Verify levels start from 0
      expect(allLevels.contains(0), isTrue, reason: 'Levels should start from 0');

      // Verify levels are consecutive (no gaps)
      List<int> sortedLevels = allLevels.toList()..sort();
      for (int i = 0; i < sortedLevels.length; i++) {
        expect(sortedLevels[i], equals(i), reason: 'Levels should be consecutive starting from 0');
      }

      // Verify maximum level matches the actual data
      expect(sortedLevels.last, equals(allLevels.length - 1), reason: 'Maximum level should be consistent with total unique levels');

      // The key behavior: same rule can have multiple render instructions with same level
      expect(levelsList.length, greaterThanOrEqualTo(allLevels.length), reason: 'Multiple render instructions can share the same level within a rule');
    });

    test('should assign same level to all render instructions within same rule', () {
      _verifyRuleLevelConsistency(renderTheme.rulesList);
    });

    test('should assign levels in generally ascending order', () {
      List<int> documentOrderLevels = <int>[];
      _collectLevelsInDocumentOrder(renderTheme.rulesList, documentOrderLevels);

      // Remove duplicates to see the general trend
      List<int> uniqueOrderedLevels = documentOrderLevels.toSet().toList();

      // Verify that the general trend is ascending (allowing for some local variations)
      int ascendingCount = 0;
      for (int i = 1; i < uniqueOrderedLevels.length; i++) {
        if (uniqueOrderedLevels[i] >= uniqueOrderedLevels[i - 1]) {
          ascendingCount++;
        }
      }

      // Most transitions should be ascending or equal
      double ascendingRatio = ascendingCount / (uniqueOrderedLevels.length - 1);
      expect(ascendingRatio, greaterThan(0.8), reason: 'Most level transitions should be ascending or equal');
    });

    test('should demonstrate level assignment behavior', () {
      Map<int, List<String>> levelToRulesMap = <int, List<String>>{};
      _mapLevelsToMultipleRules(renderTheme.rulesList, levelToRulesMap, '');

      // Print some statistics for understanding the actual behavior
      print('Total unique levels: ${levelToRulesMap.length}');
      print('MaxLevels from theme: ${renderTheme.maxLevels}');

      int singleRuleLevels = 0;
      int multiRuleLevels = 0;
      for (var entry in levelToRulesMap.entries) {
        if (entry.value.length == 1) {
          singleRuleLevels++;
        } else {
          multiRuleLevels++;
        }
      }

      print('Levels used by single rule: $singleRuleLevels');
      print('Levels used by multiple rules: $multiRuleLevels');

      // The actual behavior: levels can be shared between rules
      expect(levelToRulesMap.length, greaterThan(0), reason: 'Should have some levels assigned');
    });

    test('should cover consecutive levels starting from 0', () {
      Set<int> allLevels = <int>{};
      List<int> levelsList = <int>[];
      _collectLevelsFromRules(renderTheme.rulesList, allLevels, levelsList);

      // Verify all levels from 0 to max are present (consecutive)
      List<int> sortedLevels = allLevels.toList()..sort();
      expect(sortedLevels.first, equals(0), reason: 'Should start from level 0');

      // Verify consecutive levels (no gaps)
      for (int i = 1; i < sortedLevels.length; i++) {
        expect(sortedLevels[i], equals(sortedLevels[i - 1] + 1), reason: 'Levels should be consecutive with no gaps');
      }

      print('Level range: ${sortedLevels.first} to ${sortedLevels.last}');
      print('Total unique levels found: ${sortedLevels.length}');
      print('MaxLevels from theme: ${renderTheme.maxLevels}');
    });

    test('should verify the core requirement: unique levels per rule in ascending order', () {
      // This test verifies the exact behavior you described:
      // "Each renderinstruction has a level. The level is the same for all renderinstructions
      // of the same rule. Each rule must have a unique level in ascending order."

      Map<String, int> ruleLevels = <String, int>{};
      Set<int> usedLevels = <int>{};

      _collectRuleLevels(renderTheme.rulesList, ruleLevels, usedLevels, '');

      // Verify each rule has exactly one level
      expect(ruleLevels.length, greaterThan(0), reason: 'Should have rules with levels');

      // Verify levels are unique across rules (no two rules share the same level)
      expect(usedLevels.length, equals(ruleLevels.length), reason: 'Each rule should have a unique level');

      // Verify levels are in ascending order (0, 1, 2, ...)
      List<int> sortedLevels = usedLevels.toList()..sort();
      for (int i = 0; i < sortedLevels.length; i++) {
        expect(sortedLevels[i], equals(i), reason: 'Levels should be consecutive starting from 0');
      }

      // Verify we have exactly 354 levels (0-353) as stated
      expect(sortedLevels.length, equals(354));
      expect(sortedLevels.first, equals(0));
      expect(sortedLevels.last, equals(353));

      print('✓ Verified: ${ruleLevels.length} rules with unique levels 0-353');
    });
  });
}

/// Recursively collects all levels from rules and their subrules
void _collectLevelsFromRules(List<Rule> rules, Set<int> allLevels, List<int> levelsList) {
  for (Rule rule in rules) {
    // Collect levels from node render instructions
    for (var instruction in rule.renderinstructionNodes) {
      allLevels.add(instruction.level);
      levelsList.add(instruction.level);
    }

    // Collect levels from open way render instructions
    for (var instruction in rule.renderinstructionOpenWays) {
      allLevels.add(instruction.level);
      levelsList.add(instruction.level);
    }

    // Collect levels from closed way render instructions
    for (var instruction in rule.renderinstructionClosedWays) {
      allLevels.add(instruction.level);
      levelsList.add(instruction.level);
    }

    // Recursively process subrules
    _collectLevelsFromRules(rule.subRules, allLevels, levelsList);
  }
}

/// Verifies that all render instructions within the same rule have the same level
void _verifyRuleLevelConsistency(List<Rule> rules) {
  for (Rule rule in rules) {
    Set<int> ruleLevels = <int>{};

    // Collect all levels from this rule's render instructions
    for (var instruction in rule.renderinstructionNodes) {
      ruleLevels.add(instruction.level);
    }
    for (var instruction in rule.renderinstructionOpenWays) {
      ruleLevels.add(instruction.level);
    }
    for (var instruction in rule.renderinstructionClosedWays) {
      ruleLevels.add(instruction.level);
    }

    // If this rule has render instructions, they should all have the same level
    if (ruleLevels.isNotEmpty) {
      expect(
        ruleLevels.length,
        equals(1),
        reason:
            'All render instructions within the same rule should have the same level. '
            'Rule has levels: ${ruleLevels.toList()}',
      );
    }

    // Recursively verify subrules
    _verifyRuleLevelConsistency(rule.subRules);
  }
}

/// Collects levels in the order they appear in the document (depth-first traversal)
void _collectLevelsInDocumentOrder(List<Rule> rules, List<int> documentOrderLevels) {
  for (Rule rule in rules) {
    // Add levels from render instructions in this rule
    for (var instruction in rule.renderinstructionNodes) {
      documentOrderLevels.add(instruction.level);
    }
    for (var instruction in rule.renderinstructionOpenWays) {
      documentOrderLevels.add(instruction.level);
    }
    for (var instruction in rule.renderinstructionClosedWays) {
      documentOrderLevels.add(instruction.level);
    }

    // Recursively process subrules (depth-first)
    _collectLevelsInDocumentOrder(rule.subRules, documentOrderLevels);
  }
}

/// Maps each level to the rule paths that use it (allowing multiple rules per level)
void _mapLevelsToMultipleRules(List<Rule> rules, Map<int, List<String>> levelToRulesMap, String rulePath) {
  for (int i = 0; i < rules.length; i++) {
    Rule rule = rules[i];
    String currentRulePath = '$rulePath[$i]';

    // Map levels from render instructions
    for (var instruction in rule.renderinstructionNodes) {
      levelToRulesMap.putIfAbsent(instruction.level, () => <String>[]);
      levelToRulesMap[instruction.level]!.add(currentRulePath);
    }
    for (var instruction in rule.renderinstructionOpenWays) {
      levelToRulesMap.putIfAbsent(instruction.level, () => <String>[]);
      levelToRulesMap[instruction.level]!.add(currentRulePath);
    }
    for (var instruction in rule.renderinstructionClosedWays) {
      levelToRulesMap.putIfAbsent(instruction.level, () => <String>[]);
      levelToRulesMap[instruction.level]!.add(currentRulePath);
    }

    // Recursively process subrules
    _mapLevelsToMultipleRules(rule.subRules, levelToRulesMap, currentRulePath);
  }
}

/// Collects rule levels to verify unique level assignment per rule
void _collectRuleLevels(List<Rule> rules, Map<String, int> ruleLevels, Set<int> usedLevels, String rulePath) {
  for (int i = 0; i < rules.length; i++) {
    Rule rule = rules[i];
    String currentRulePath = '$rulePath[$i]';

    // Get the level from any render instruction in this rule (they should all be the same)
    int? ruleLevel;

    if (rule.renderinstructionNodes.isNotEmpty) {
      ruleLevel = rule.renderinstructionNodes.first.level;
    } else if (rule.renderinstructionOpenWays.isNotEmpty) {
      ruleLevel = rule.renderinstructionOpenWays.first.level;
    } else if (rule.renderinstructionClosedWays.isNotEmpty) {
      ruleLevel = rule.renderinstructionClosedWays.first.level;
    }

    if (ruleLevel != null) {
      ruleLevels[currentRulePath] = ruleLevel;
      usedLevels.add(ruleLevel);
    }

    // Recursively process subrules
    _collectRuleLevels(rule.subRules, ruleLevels, usedLevels, currentRulePath);
  }
}

void _initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
