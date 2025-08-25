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
    // Optimized hash function using FNV-1a algorithm for better distribution
    // and reduced collision probability compared to simple XOR operations
    int hash = 2166136261; // FNV offset basis (32-bit)
    
    // Hash tags using FNV-1a algorithm
    for (final tag in _tags) {
      hash ^= tag.hashCode;
      hash *= 16777619; // FNV prime (32-bit)
    }
    
    // Combine with indoor level
    hash ^= _indoorLevel;
    hash *= 16777619;
    
    return hash;
  }
}
