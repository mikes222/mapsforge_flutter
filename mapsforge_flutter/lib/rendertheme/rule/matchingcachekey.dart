import '../../model/tag.dart';

import 'closed.dart';

class MatchingCacheKey {
  final Closed closed;
  final List<Tag> tags;
  final Set<Tag> tagsWithoutName;
  final int zoomLevel;

  MatchingCacheKey(this.tags, this.zoomLevel, this.closed)
      : tagsWithoutName = new Set<Tag>() {
    if (this.tags != null) {
      for (Tag tag in tags) {
        if ("name" != (tag.key)) {
          this.tagsWithoutName.add(tag);
        }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchingCacheKey &&
          runtimeType == other.runtimeType &&
          closed == other.closed &&
          tags == other.tags &&
          tagsWithoutName == other.tagsWithoutName &&
          zoomLevel == other.zoomLevel;

  @override
  int get hashCode =>
      closed.hashCode ^
      tags.hashCode ^
      tagsWithoutName.hashCode ^
      zoomLevel.hashCode;
}
