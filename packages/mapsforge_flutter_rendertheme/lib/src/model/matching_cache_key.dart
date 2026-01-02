import 'package:mapsforge_flutter_core/model.dart';

class MatchingCacheKey {
  final ITagCollection _tags;
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
  int get hashCode {
    //print("Hash for $_tags and $_indoorLevel is ${_tags.hashCode} and ${_indoorLevel.hashCode}");
    return _tags.hashCode ^ _indoorLevel.hashCode; //    Object.hash(_tags, _indoorLevel);
  }
}
