import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closedmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/elementmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/keymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/negativematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/valuematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/rulebuilder.dart';
import 'package:logging/logging.dart';

// TODO implement RuleOptimizer again
class RuleOptimizer {
  static final _log = new Logger('RuleOptimizer');

  static AttributeMatcher optimize(AttributeMatcher attributeMatcher, List<RuleBuilder> ruleStack) {
    if (attributeMatcher is AnyMatcher || attributeMatcher is NegativeMatcher) {
      return attributeMatcher;
    } else if (attributeMatcher is KeyMatcher) {
      return optimizeKeyMatcher(attributeMatcher, ruleStack);
    } else if (attributeMatcher is ValueMatcher) {
      return optimizeValueMatcher(attributeMatcher, ruleStack);
    }

    throw new Exception("unknown AttributeMatcher:$attributeMatcher");
  }

  static ClosedMatcher optimizeClosedMatcher(ClosedMatcher closedMatcher, List<RuleBuilder> ruleStack) {
    if (closedMatcher is AnyMatcher) {
      return closedMatcher;
    }

    for (RuleBuilder rule in ruleStack) {
      if (rule.getClosedMatcher().isCoveredByClosedMatcher(closedMatcher)) {
        return const AnyMatcher();
      } else if (!closedMatcher.isCoveredByClosedMatcher(closedMatcher)) {
        _log.warning("unreachable rule (closed)");
      }
    }
    return closedMatcher;
  }

  static ElementMatcher optimizeElementMatcher(ElementMatcher elementMatcher, List<RuleBuilder> ruleBuilderStack) {
    if (elementMatcher is AnyMatcher) {
      return elementMatcher;
    }

    for (RuleBuilder rule in ruleBuilderStack) {
      if (rule.getElementMatcher().isCoveredByElementMatcher(elementMatcher)) {
        return const AnyMatcher();
      } else if (!elementMatcher.isCoveredByElementMatcher(rule.getElementMatcher())) {
        _log.warning("unreachable rule (e)");
      }
    }

    return elementMatcher;
  }

  static AttributeMatcher optimizeKeyMatcher(KeyMatcher keyMatcher, List<RuleBuilder> ruleBuilderStack) {
    AttributeMatcher? result = ruleBuilderStack
        .where((test) => test.negativeMatcher == null)
        .map((element) => element.keyMatcher)
        .firstWhereOrNull((test) => test.isCoveredByAttributeMatcher(keyMatcher));
    if (result != null) {
      return const AnyMatcher();
    }
    return keyMatcher;
  }

  static AttributeMatcher optimizeValueMatcher(AttributeMatcher attributeMatcher, List<RuleBuilder> ruleBuilderStack) {
    AttributeMatcher? result = ruleBuilderStack
        .where((test) => test.negativeMatcher == null)
        .map((element) => element.valueMatcher)
        .firstWhereOrNull((test) => test.isCoveredByAttributeMatcher(attributeMatcher));
    if (result != null) {
      return const AnyMatcher();
    }
    return attributeMatcher;
  }
}
