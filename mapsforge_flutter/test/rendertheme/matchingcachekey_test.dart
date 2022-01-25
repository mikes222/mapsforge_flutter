import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/closed.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/matchingcachekey.dart';

void main() {
  test('split-test1', () {
    Tag tag1 = const Tag('', '');
    List<Tag> tagList1 = [tag1];
    MatchingCacheKey m1 = MatchingCacheKey(tagList1, 5, 0, Closed.YES);
    MatchingCacheKey m2 = MatchingCacheKey(tagList1, 5, 0, Closed.YES);
    MatchingCacheKey m3 = MatchingCacheKey([tag1], 5, 0, Closed.YES);
    MatchingCacheKey m4 =
        const MatchingCacheKey([const Tag('', '')], 5, 0, Closed.YES);
    MatchingCacheKey m5 =
        const MatchingCacheKey([const Tag('test', '')], 5, 0, Closed.YES);
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
