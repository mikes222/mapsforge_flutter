import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/matching_cache_key.dart';
import 'package:test/test.dart';

void main() {
  test('split-test1', () {
    Tag tag1 = const Tag('', '');
    var tagList1 = TagCollection(tags: [tag1]);
    MatchingCacheKey m1 = MatchingCacheKey(tagList1, 0);
    MatchingCacheKey m2 = MatchingCacheKey(tagList1, 0);
    MatchingCacheKey m3 = MatchingCacheKey(TagCollection(tags: [tag1]), 0);
    MatchingCacheKey m4 = MatchingCacheKey(TagCollection(tags: [Tag('', '')]), 0);
    MatchingCacheKey m5 = MatchingCacheKey(TagCollection(tags: [Tag('test', '')]), 0);
    expect(tag1 == const Tag('', ''), true);
    //    expect(tagList1 == [tag1], true);
    //    expect(m1.hashCode, m1.hashCode);
    expect(m1.hashCode, m2.hashCode);
    expect(m1.hashCode, m3.hashCode);
    expect(m1.hashCode, m4.hashCode);
    expect(m1.hashCode - m5.hashCode, isNot(0));
    expect(m1 == m2, true);
    expect(m1 == m3, true);
    expect(m1 == m4, true);
    expect(m1 == m5, false);
  });
}
