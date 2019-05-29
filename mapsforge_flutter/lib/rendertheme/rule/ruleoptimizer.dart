import '../../rendertheme/rule/valuematcher.dart';

import 'anymatcher.dart';
import 'attributematcher.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';
import 'keymatcher.dart';
import 'negativematcher.dart';
import 'positiverule.dart';
import 'rule.dart';

class RuleOptimizer {
  static AttributeMatcher optimize(
      AttributeMatcher attributeMatcher, Stack<Rule> ruleStack) {
    if (attributeMatcher is AnyMatcher || attributeMatcher is NegativeMatcher) {
      return attributeMatcher;
    } else if (attributeMatcher is KeyMatcher) {
      return optimizeKeyMatcher(attributeMatcher, ruleStack);
    } else if (attributeMatcher is ValueMatcher) {
      return optimizeValueMatcher(attributeMatcher, ruleStack);
    }

    throw new Exception("unknown AttributeMatcher:$attributeMatcher");
  }

  static ClosedMatcher optimize(
      ClosedMatcher closedMatcher, Stack<Rule> ruleStack) {
    if (closedMatcher is AnyMatcher) {
      return closedMatcher;
    }

    for (int i = 0, n = ruleStack.size(); i < n; ++i) {
      if (ruleStack.get(i).closedMatcher.isCoveredBy(closedMatcher)) {
        return AnyMatcher.INSTANCE;
      } else if (!closedMatcher.isCoveredBy(ruleStack.get(i).closedMatcher)) {
        LOGGER.warning("unreachable rule (closed)");
      }
    }

    return closedMatcher;
  }

  static ElementMatcher optimize(
      ElementMatcher elementMatcher, Stack<Rule> ruleStack) {
    if (elementMatcher is AnyMatcher) {
      return elementMatcher;
    }

    for (int i = 0, n = ruleStack.size(); i < n; ++i) {
      Rule rule = ruleStack.get(i);
      if (rule.elementMatcher.isCoveredBy(elementMatcher)) {
        return AnyMatcher.INSTANCE;
      } else if (!elementMatcher.isCoveredBy(rule.elementMatcher)) {
        LOGGER.warning("unreachable rule (e)");
      }
    }

    return elementMatcher;
  }

  static AttributeMatcher optimizeKeyMatcher(
      AttributeMatcher attributeMatcher, Stack<Rule> ruleStack) {
    for (int i = 0, n = ruleStack.size(); i < n; ++i) {
      if (ruleStack.get(i) is PositiveRule) {
        PositiveRule positiveRule = ruleStack.get(i);
        if (positiveRule.keyMatcher.isCoveredBy(attributeMatcher)) {
          return AnyMatcher.INSTANCE;
        }
      }
    }

    return attributeMatcher;
  }

  static AttributeMatcher optimizeValueMatcher(
      AttributeMatcher attributeMatcher, Stack<Rule> ruleStack) {
    for (int i = 0, n = ruleStack.size(); i < n; ++i) {
      if (ruleStack.get(i) is PositiveRule) {
        PositiveRule positiveRule = ruleStack.get(i);
        if (positiveRule.valueMatcher.isCoveredBy(attributeMatcher)) {
          return AnyMatcher.INSTANCE;
        }
      }
    }

    return attributeMatcher;
  }
}
