import 'package:dart_common/model.dart';

class MatchingCacheKey {
  final List<Tag> _tags;
  final int _indoorLevel;

  const MatchingCacheKey(this._tags, this._indoorLevel);

  @override
  String toString() {
    return 'MatchingCacheKey{_tags: $_tags, _indoorLevel: $_indoorLevel}';
  }

  /// We need to compare the contents of the tags, therefore the default hash function would not work
  /// todo switch to a dedicated class for list of tags.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchingCacheKey &&
          runtimeType == other.runtimeType &&
          _tags.fold(15, (dynamic previousValue, element) => previousValue ^ element.hashCode) ==
              other._tags.fold(15, (dynamic previousValue, element) => previousValue ^ element.hashCode) &&
          _indoorLevel == other._indoorLevel;

  @override
  int get hashCode {
    int tagHash = _tags.fold<int>(15, ((previousValue, element) => previousValue ^ element.hashCode));
    return tagHash ^ _indoorLevel.hashCode << 5;
  }
}
