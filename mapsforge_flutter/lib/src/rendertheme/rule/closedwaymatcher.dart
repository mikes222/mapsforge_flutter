import 'closed.dart';
import 'closedmatcher.dart';

class ClosedWayMatcher implements ClosedMatcher {
  static final ClosedWayMatcher INSTANCE = new ClosedWayMatcher();

  ClosedWayMatcher() {
    // do nothing
  }

  @override
  bool isCoveredByClosedMatcher(ClosedMatcher? closedMatcher) {
    return closedMatcher!.matchesClosed(Closed.YES);
  }

  @override
  bool matchesClosed(Closed closed) {
    return closed == Closed.YES;
  }
}
