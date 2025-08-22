import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/rendertheme_zoomlevel.dart';
import 'package:dart_rendertheme/src/rule/rule.dart';

/// A RenderTheme defines how ways and nodes are drawn.
class Rendertheme {
  static final int MATCHING_CACHE_SIZE = 1024;

  /// The rendertheme can set the base stroke with factor
  double baseStrokeWidth = 1;

  /// The rendertheme can set the base text size factor
  double baseTextSize = 1;

  final bool? hasBackgroundOutside;

  /// the maximum number of levels in the rendertheme
  final int levels;
  final int? mapBackground;
  final int? mapBackgroundOutside;

  /// A list of rules which contains a list of rules which ...
  /// see defaultrender.xml how this is constructed.
  final List<Rule> rulesList; // NOPMD we need specific interface

  /// ZoomLevel dependent (iterative) list of rules
  final Map<int, RenderthemeZoomlevel> _renderthemeZoomlevels = {};

  late final String forHash;

  Rendertheme({required this.levels, this.mapBackground, this.mapBackgroundOutside, required this.rulesList, this.hasBackgroundOutside});

  /**
   * @return the number of distinct drawing levels required by this RenderTheme.
   */
  int getLevels() {
    return levels;
  }

  /**
   * @return the map background color of this RenderTheme.
   */
  int? getMapBackground() {
    return this.mapBackground;
  }

  /**
   * @return the background color that applies to areas outside the map.
   */
  int? getMapBackgroundOutside() {
    return this.mapBackgroundOutside;
  }

  /**
   * @return true if map color is defined for outside areas.
   */
  bool? hasMapBackgroundOutside() {
    return this.hasBackgroundOutside;
  }

  /// Scales the stroke width of this RenderTheme by the given factor for a given zoom level
  ///
  /// @param scaleFactor the factor by which the stroke width should be scaled.
  /// @param zoomLevel   the zoom level to which this is applied.
  RenderthemeZoomlevel prepareZoomlevel(int zoomlevel) {
    if (_renderthemeZoomlevels.containsKey(zoomlevel)) return _renderthemeZoomlevels[zoomlevel]!;
    List<Rule> rules = [];
    for (Rule rule in rulesList) {
      Rule? r = rule.forZoomlevel(zoomlevel);
      if (r != null) {
        rules.add(r);
        r.parent = null;
      }
    }
    RenderthemeZoomlevel renderthemeLevel = RenderthemeZoomlevel(rulesList: rules);
    for (Rule rule in rules) {
      rule.secondPass();
    }
    _renderthemeZoomlevels[zoomlevel] = renderthemeLevel;
    return renderthemeLevel;
  }

  void complete() {
    //    this.rulesList.trimToSize();
    //    this.hillShadings.trimToSize();
    for (var element in rulesList) {
      element.onComplete();
    }
  }

  void traverseRules(RuleVisitor visitor) {
    for (var rule in rulesList) {
      rule.apply(visitor);
    }
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if the argument is never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    ZoomlevelRange? result;
    for (var rule in rulesList) {
      ZoomlevelRange? range = rule.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeWay(Waypath waypath, List<Tag> tags) {
    bool isClosedWay = waypath.isClosedWay();
    ZoomlevelRange? result;
    for (var rule in rulesList) {
      ZoomlevelRange? range = isClosedWay ? rule.getZoomlevelRangeClosedWay(tags) : rule.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }
}
