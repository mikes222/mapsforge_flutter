import '../../model/tag.dart';

import 'closed.dart';

class MatchingCacheKey {
  final Closed _closed;
  final List<Tag> _tags;
  // final Set<Tag> _tagsWithoutName;
  final int _zoomLevel;
  final int _indoorLevel;

  MatchingCacheKey(this._tags, this._zoomLevel, this._indoorLevel, this._closed) {
    //: tagsWithoutName = Set<Tag>() {
//    if (this.tags != null) {
//      for (Tag tag in tags) {
//        if ("name" != (tag.key)) {
////          this.tagsWithoutName.add(tag);
//        }
//      }
//    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MatchingCacheKey &&
              runtimeType == other.runtimeType &&
              _closed == other._closed &&
              _tags == other._tags &&
              _zoomLevel == other._zoomLevel &&
              _indoorLevel == other._indoorLevel;

  @override
  int get hashCode {
    int tagHash = _tags?.fold(15, (previousValue, element) => previousValue ^ element.hashCode) ?? 31;
    return _closed.hashCode ^ tagHash ^ _zoomLevel.hashCode ^ _indoorLevel.hashCode << 5;
  }
}