import 'closed.dart';

/// A matcher for closed ways
abstract class ClosedMatcher {
  bool isCoveredByClosedMatcher(ClosedMatcher closedMatcher);

  bool matchesClosed(Closed closed);

  @override
  String toString() {
    return 'ClosedMatcher{}';
  }
}
