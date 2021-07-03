import 'package:mapsforge_flutter/src/rendertheme/xml/renderthemebuilder.dart';

import '../../datastore/pointofinterest.dart';
import '../../renderer/polylinecontainer.dart';
import '../../rendertheme/renderinstruction/hillshading.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../../rendertheme/rule/rule.dart';
import '../rendercallback.dart';
import '../rendercontext.dart';
import 'closed.dart';
import 'matchingcachekey.dart';

/// A RenderTheme defines how ways and nodes are drawn.
class RenderTheme {
  static final int MATCHING_CACHE_SIZE = 1024;

  final double baseStrokeWidth;
  final double baseTextSize;
  final bool? hasBackgroundOutside;

  /// the maximum number of levels in the rendertheme
  final int levels;
  final int? mapBackground;
  final int? mapBackgroundOutside;
  late Map<MatchingCacheKey, List<RenderInstruction>> wayMatchingCache;
  late Map<MatchingCacheKey, List<RenderInstruction>> poiMatchingCache;
  final List<Rule> rulesList; // NOPMD we need specific interface
  List<Hillshading> hillShadings = []; // NOPMD specific interface for trimToSize
  final List<RenderInstruction> initPendings;

  final Map<int, double> strokeScales = new Map();
  final Map<int, double> textScales = new Map();

  RenderTheme(RenderThemeBuilder renderThemeBuilder, this.initPendings)
      : //assert(renderThemeBuilder.maxLevel > 0),
        baseStrokeWidth = renderThemeBuilder.baseStrokeWidth,
        baseTextSize = renderThemeBuilder.baseTextSize,
        hasBackgroundOutside = renderThemeBuilder.hasBackgroundOutside,
        mapBackground = renderThemeBuilder.mapBackground,
        mapBackgroundOutside = renderThemeBuilder.mapBackgroundOutside,
        rulesList = [],
        levels = renderThemeBuilder.maxLevel + 1 {
    this.poiMatchingCache = new Map();
    this.wayMatchingCache = new Map();
  }

  /**
   * Must be called when this RenderTheme gets destroyed to clean up and free resources.
   */
  void dispose() {
    this.poiMatchingCache.clear();
    this.wayMatchingCache.clear();
    for (Rule r in this.rulesList) {
      r.dispose();
    }
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
   * Matches a closed way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  List<RenderInstruction> matchClosedWay(final RenderContext renderContext, PolylineContainer way) {
    return _matchWay(renderContext, Closed.YES, way);
  }

  /**
   * Matches a linear way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  List<RenderInstruction> matchLinearWay(final RenderContext renderContext, PolylineContainer way) {
    return _matchWay(renderContext, Closed.NO, way);
  }

  /**
   * Matches a node with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param poi            the point of interest.
   */
  List<RenderInstruction> matchNode(final RenderContext renderContext, PointOfInterest poi) {
    MatchingCacheKey matchingCacheKey =
        new MatchingCacheKey(poi.tags, renderContext.job.tile.zoomLevel, renderContext.job.tile.indoorLevel, Closed.NO);

    List<RenderInstruction>? matchingList = this.poiMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];

      rulesList.forEach((element) {
        element.matchNode(renderContext, matchingList!, poi, initPendings);
      });
      this.poiMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  /**
   * Scales the stroke width of this RenderTheme by the given factor for a given zoom level
   *
   * @param scaleFactor the factor by which the stroke width should be scaled.
   * @param zoomLevel   the zoom level to which this is applied.
   */
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (!strokeScales.containsKey(zoomLevel) || scaleFactor != strokeScales[zoomLevel]) {
      rulesList.forEach((rule) {
        if (rule.zoomMin <= zoomLevel && rule.zoomMax >= zoomLevel) {
          rule.scaleStrokeWidth(scaleFactor * this.baseStrokeWidth, zoomLevel);
        }
      });
      // for (int i = 0, n = this.rulesList.length; i < n; ++i) {
      //   Rule rule = this.rulesList.elementAt(i);
      // }
      strokeScales[zoomLevel] = scaleFactor;
    }
  }

  /**
   * Scales the text size of this RenderTheme by the given factor for a given zoom level.
   *
   * @param scaleFactor the factor by which the text size should be scaled. This comes from [DisplayModel].userScaleFactor
   * @param zoomLevel   the zoom level to which this is applied.
   */
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    if (!textScales.containsKey(zoomLevel) || scaleFactor != textScales[zoomLevel]) {
      rulesList.forEach((rule) {
        if (rule.zoomMin <= zoomLevel && rule.zoomMax >= zoomLevel) {
          rule.scaleTextSize(scaleFactor * this.baseTextSize, zoomLevel);
        }
      });
      textScales[zoomLevel] = scaleFactor;
    }
  }

  void addRule(Rule rule) {
    this.rulesList.add(rule);
  }

  void addHillShadings(Hillshading hillshading) {
    this.hillShadings.add(hillshading);
  }

  void complete() {
//    this.rulesList.trimToSize();
//    this.hillShadings.trimToSize();
    rulesList.forEach((element) {
      element.onComplete();
    });
  }

  // void setLevels(int? levels) {
  //   this.levels = levels;
  // }

  List<RenderInstruction> _matchWay(final RenderContext renderContext, Closed closed, PolylineContainer way) {
    MatchingCacheKey matchingCacheKey =
        MatchingCacheKey(way.getTags(), way.getUpperLeft().zoomLevel, way.getUpperLeft().indoorLevel, closed);

    List<RenderInstruction>? matchingList = this.wayMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];
      this.rulesList.forEach((rule) {
        rule.matchWay(way, way.getUpperLeft(), closed, matchingList!);
      });

      this.wayMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  void traverseRules(RuleVisitor visitor) {
    rulesList.forEach((element) {
      element.apply(visitor);
    });
  }

//  void matchHillShadings(StandardRenderer renderer, RenderContext renderContext) {
//    for (Hillshading hillShading in hillShadings) hillShading.render(renderContext, renderer.hillsRenderConfig);
//  }

  @override
  String toString() {
    return 'RenderTheme{baseStrokeWidth: $baseStrokeWidth, baseTextSize: $baseTextSize, hasBackgroundOutside: $hasBackgroundOutside, levels: $levels, mapBackground: $mapBackground, mapBackgroundOutside: $mapBackgroundOutside, wayMatchingCache: $wayMatchingCache, poiMatchingCache: $poiMatchingCache, rulesList: $rulesList, hillShadings: $hillShadings, strokeScales: $strokeScales, textScales: $textScales}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderTheme &&
          runtimeType == other.runtimeType &&
          baseStrokeWidth == other.baseStrokeWidth &&
          baseTextSize == other.baseTextSize &&
          hasBackgroundOutside == other.hasBackgroundOutside &&
          levels == other.levels &&
          mapBackground == other.mapBackground &&
          mapBackgroundOutside == other.mapBackgroundOutside;

  @override
  int get hashCode =>
      baseStrokeWidth.hashCode ^
      baseTextSize.hashCode ^
      hasBackgroundOutside.hashCode ^
      levels.hashCode ^
      mapBackground.hashCode ^
      mapBackgroundOutside.hashCode;
}
