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
          _indoorLevel == other._indoorLevel &&
          _tagsEqual(other._tags);
  
  /// Optimized tag comparison to avoid repeated hash calculations
  bool _tagsEqual(List<Tag> otherTags) {
    if (_tags.length != otherTags.length) return false;
    for (int i = 0; i < _tags.length; i++) {
      if (_tags[i] != otherTags[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // Use a better hash function with prime numbers for better distribution
    int hash = 17;
    for (final tag in _tags) {
      hash = hash * 31 + tag.hashCode;
    }
    hash = hash * 31 + _indoorLevel.hashCode;
    return hash;
  }
}
