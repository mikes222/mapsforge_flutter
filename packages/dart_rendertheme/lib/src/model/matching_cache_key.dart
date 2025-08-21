import 'package:dart_common/model.dart';

class MatchingCacheKey {
  final List<Tag> _tags;
  final int _indoorLevel;

  const MatchingCacheKey(this._tags, this._indoorLevel);

  @override
  String toString() {
    return 'MatchingCacheKey{_tags: $_tags, _indoorLevel: $_indoorLevel}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MatchingCacheKey && runtimeType == other.runtimeType && _tags == other._tags && _indoorLevel == other._indoorLevel;

  @override
  int get hashCode => Object.hash(_tags, _indoorLevel);
}
