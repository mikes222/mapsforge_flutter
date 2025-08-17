import '../../../core.dart';
import '../../../datastore.dart';
import '../../../maps.dart';
import '../../model/zoomlevel_range.dart';
import '../../rendertheme/rule/rule.dart';
import '../xml/renderinstruction/renderinstruction_hillshading.dart';

/// A RenderTheme defines how ways and nodes are drawn.
class RenderTheme {
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
  final Map<int, RenderthemeLevel> renderthemeLevels = {};

  List<RenderinstructionHillshading> hillShadings = []; // NOPMD specific interface for trimToSize

  late final String forHash;

  RenderTheme(RenderThemeBuilder renderThemeBuilder)
      : //assert(renderThemeBuilder.maxLevel > 0),
        baseStrokeWidth = renderThemeBuilder.baseStrokeWidth,
        baseTextSize = renderThemeBuilder.baseTextSize,
        hasBackgroundOutside = renderThemeBuilder.hasBackgroundOutside,
        mapBackground = renderThemeBuilder.mapBackground,
        mapBackgroundOutside = renderThemeBuilder.mapBackgroundOutside,
        rulesList = [],
        levels = renderThemeBuilder.maxLevel + 1 {
    forHash = renderThemeBuilder.forHash;
  }

  /**
   * Must be called when this RenderTheme gets destroyed to clean up and free resources.
   */
  void dispose() {
    for (Rule r in this.rulesList) {
      r.dispose();
    }
    for (RenderthemeLevel renderthemeLevel in renderthemeLevels.values) {
      renderthemeLevel.dispose();
    }
    renderthemeLevels.clear();
  }

  /**
   * @return the number of distinct drawing levels required by this RenderTheme.
   */
  int getLevels() {
    return this.levels;
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

  /**
   * Scales the stroke width of this RenderTheme by the given factor for a given zoom level
   *
   * @param scaleFactor the factor by which the stroke width should be scaled.
   * @param zoomLevel   the zoom level to which this is applied.
   */
  RenderthemeLevel prepareZoomlevel(int zoomlevel) {
    if (renderthemeLevels.containsKey(zoomlevel)) return renderthemeLevels[zoomlevel]!;
    List<Rule> rules = [];
    for (Rule rule in rulesList) {
      Rule? r = rule.matchForZoomlevel(zoomlevel);
      if (r != null) {
        rules.add(r);
      }
    }
    RenderthemeLevel renderthemeLevel = RenderthemeLevel(rulesList: rules);
    renderthemeLevels[zoomlevel] = renderthemeLevel;
    return renderthemeLevel;
  }

  void addRule(Rule rule) {
    this.rulesList.add(rule);
  }

  void addHillShadings(RenderinstructionHillshading hillshading) {
    this.hillShadings.add(hillshading);
  }

  void complete() {
//    this.rulesList.trimToSize();
//    this.hillShadings.trimToSize();
    rulesList.forEach((element) {
      element.onComplete();
    });
  }

  void traverseRules(RuleVisitor visitor) {
    rulesList.forEach((rule) {
      rule.apply(visitor);
    });
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    ZoomlevelRange? result;
    rulesList.forEach((rule) {
      ZoomlevelRange? range = rule.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result!.widenTo(range);
        }
      }
    });
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeWay(Waypath waypath, List<Tag> tags) {
    bool isClosedWay = waypath.isClosedWay();
    ZoomlevelRange? result;
    rulesList.forEach((rule) {
      ZoomlevelRange? range = isClosedWay ? rule.getZoomlevelRangeClosedWay(tags) : rule.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result!.widenTo(range);
        }
      }
    });
    return result;
  }
}
