import 'closed.dart';
import 'closedmatcher.dart';

class LinearWayMatcher implements ClosedMatcher {
  static final LinearWayMatcher INSTANCE = const LinearWayMatcher();

  const LinearWayMatcher();

  @override
  bool isCoveredByClosedMatcher(ClosedMatcher closedMatcher) {
    return closedMatcher.matchesClosed(Closed.NO);
  }

  @override
  bool matchesClosed(Closed closed) {
    return closed == Closed.NO;
  }
}
