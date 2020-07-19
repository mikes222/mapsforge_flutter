import '../../model/tag.dart';

import 'closed.dart';

class MatchingCacheKey {
  final Closed closed;
  final List<Tag> tags;
//  final Set<Tag> tagsWithoutName;
  final int zoomLevel;

  int _hashKey;

  MatchingCacheKey(List<Tag> tags, this.zoomLevel, this.closed) : this.tags = List() {
    //: tagsWithoutName = Set<Tag>() {
//    if (this.tags != null) {
//      for (Tag tag in tags) {
//        if ("name" != (tag.key)) {
////          this.tagsWithoutName.add(tag);
//        }
//      }
//    }
    this.tags.addAll(tags);
    _hashKey = hashCode;
    // do not clear the given list
    this.tags.clear();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MatchingCacheKey && runtimeType == other.runtimeType && _hashKey == other._hashKey;
//          closed == other.closed &&
//          tags == other.tags &&
//          tagsWithoutName == other.tagsWithoutName &&
//          zoomLevel == other.zoomLevel;

  @override
  int get hashCode {
    if (_hashKey != null) return _hashKey;
    int tagHash = tags?.fold(15, (previousValue, element) => previousValue ^ element.hashCode) ?? 31;
    return closed.hashCode ^ tagHash ^ zoomLevel.hashCode;
  }
}
