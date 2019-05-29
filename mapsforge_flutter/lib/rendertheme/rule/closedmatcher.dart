import 'closed.dart';

abstract class ClosedMatcher {
  bool isCoveredByClosedMatcher(ClosedMatcher closedMatcher);

  bool matchesClosed(Closed closed);
}
