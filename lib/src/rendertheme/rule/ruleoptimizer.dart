import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../rendertheme/rule/valuematcher.dart';
import 'anymatcher.dart';
import 'attributematcher.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';
import 'keymatcher.dart';
import 'negativematcher.dart';
import 'positiverule.dart';

// TODO implement RuleOptimizer again
class RuleOptimizer {
  static final _log = new Logger('RuleOptimizer');

  static AttributeMatcher optimize(
      AttributeMatcher attributeMatcher, List<RuleBuilder> ruleStack) {
    if (attributeMatcher is AnyMatcher || attributeMatcher is NegativeMatcher) {
      return attributeMatcher;
    } else if (attributeMatcher is KeyMatcher) {
      return optimizeKeyMatcher(attributeMatcher, ruleStack);
    } else if (attributeMatcher is ValueMatcher) {
      return optimizeValueMatcher(attributeMatcher, ruleStack);
    }

    throw new Exception("unknown AttributeMatcher:$attributeMatcher");
  }

  static ClosedMatcher optimizeClosedMatcher(
      ClosedMatcher closedMatcher, List<RuleBuilder> ruleStack) {
    if (closedMatcher is AnyMatcher) {
      return closedMatcher;
    }

    for (int i = 0, n = ruleStack.length; i < n; ++i) {
      if (ruleStack
          .elementAt(i)
          .closedMatcher!
          .isCoveredByClosedMatcher(closedMatcher)) {
        return AnyMatcher.INSTANCE;
      } else if (!closedMatcher
          .isCoveredByClosedMatcher(ruleStack.elementAt(i).closedMatcher!)) {
        _log.warning("unreachable rule (closed)");
      }
    }

    return closedMatcher;
  }

  static ElementMatcher optimizeElementMatcher(
      ElementMatcher elementMatcher, List<RuleBuilder> ruleStack) {
    if (elementMatcher is AnyMatcher) {
      return elementMatcher;
    }

    for (int i = 0, n = ruleStack.length; i < n; ++i) {
      RuleBuilder rule = ruleStack.elementAt(i);
      if (rule.elementMatcher!.isCoveredByElementMatcher(elementMatcher)) {
        return AnyMatcher.INSTANCE;
      } else if (!elementMatcher
          .isCoveredByElementMatcher(rule.elementMatcher)) {
        _log.warning("unreachable rule (e)");
      }
    }

    return elementMatcher;
  }

  static AttributeMatcher optimizeKeyMatcher(
      AttributeMatcher attributeMatcher, List<RuleBuilder> ruleStack) {
    for (int i = 0, n = ruleStack.length; i < n; ++i) {
      if (ruleStack.elementAt(i) is PositiveRule) {
        PositiveRule positiveRule = ruleStack.elementAt(i) as PositiveRule;
        if (positiveRule.keyMatcher
            .isCoveredByAttributeMatcher(attributeMatcher)) {
          return AnyMatcher.INSTANCE;
        }
      }
    }

    return attributeMatcher;
  }

  static AttributeMatcher optimizeValueMatcher(
      AttributeMatcher attributeMatcher, List<RuleBuilder> ruleStack) {
    for (int i = 0, n = ruleStack.length; i < n; ++i) {
      if (ruleStack.elementAt(i) is PositiveRule) {
        PositiveRule positiveRule = ruleStack.elementAt(i) as PositiveRule;
        if (positiveRule.valueMatcher
            .isCoveredByAttributeMatcher(attributeMatcher)) {
          return AnyMatcher.INSTANCE;
        }
      }
    }

    return attributeMatcher;
  }
}
