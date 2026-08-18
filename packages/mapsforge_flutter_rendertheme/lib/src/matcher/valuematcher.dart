import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';

class ValueMatcher implements AttributeMatcher {
  final Set<String> values;

  ValueMatcher(List<String> values) : values = Set.unmodifiable(values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }
    if (attributeMatcher is AnyMatcher) {
      return true;
    }
    if (attributeMatcher is ValueMatcher) {
      return attributeMatcher.values.every(values.contains);
    }
    return false;
  }

  @override
  bool matchesTagList(ITagCollection tags) {
    return tags.valueMatchesTagList(values);
  }

  @override
  String toString() {
    return 'ValueMatcher{values: ${values.toList()}}';
  }
}
