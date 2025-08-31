import 'closed.dart';
import 'closedmatcher.dart';

class ClosedWayMatcher implements ClosedMatcher {
  const ClosedWayMatcher();

  @override
  bool isCoveredByClosedMatcher(ClosedMatcher closedMatcher) {
    return closedMatcher.matchesClosed(Closed.YES);
  }

  @override
  bool matchesClosed(Closed closed) {
    return closed == Closed.YES;
  }

  @override
  String toString() {
    return 'ClosedWayMatcher{}';
  }
}
