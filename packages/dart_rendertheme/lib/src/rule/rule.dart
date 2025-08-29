import 'package:collection/collection.dart';
import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/rule/symbol_searcher.dart';

abstract class Rule implements SymbolSearcher {
  // parent rule
  late final Rule? parent;

  final String? cat;
  final ZoomlevelRange zoomlevelRange;
  final List<Rule> subRules;

  final List<RenderinstructionNode> renderinstructionNodes;

  final List<RenderinstructionWay> renderinstructionOpenWays;

  final List<RenderinstructionWay> renderinstructionClosedWays;

  Rule({
    this.cat,
    required this.zoomlevelRange,
    required this.subRules,
    required this.renderinstructionNodes,
    required this.renderinstructionOpenWays,
    required this.renderinstructionClosedWays,
  }) : assert(
         subRules.isNotEmpty ||
             (subRules.isEmpty && (renderinstructionNodes.isNotEmpty || renderinstructionOpenWays.isNotEmpty || renderinstructionClosedWays.isNotEmpty)),
       ) {
    for (var rule in subRules) {
      rule.parent = this;
    }
  }

  void dispose() {
    for (Rule rule in subRules) {
      rule.dispose();
    }
    for (RenderinstructionNode renderinstruction in renderinstructionNodes) {
      renderinstruction.dispose();
    }
    for (RenderinstructionWay renderinstruction in renderinstructionOpenWays) {
      renderinstruction.dispose();
    }
    for (RenderinstructionWay renderinstruction in renderinstructionClosedWays) {
      renderinstruction.dispose();
    }
  }

  void secondPass() {
    for (Rule rule in subRules) {
      rule.secondPass();
    }
    for (RenderinstructionNode renderinstruction in renderinstructionNodes) {
      renderinstruction.secondPass(this);
    }
    for (RenderinstructionWay renderinstruction in renderinstructionOpenWays) {
      renderinstruction.secondPass(this);
    }
    for (RenderinstructionWay renderinstruction in renderinstructionClosedWays) {
      renderinstruction.secondPass(this);
    }
  }

  Rule? forZoomlevel(int zoomlevel, int Function());

  void apply(RuleVisitor v) {
    v.apply(this);
  }

  /// Returns true if this rule can be applied for the given zoomLevel.
  bool matchesForZoomLevel(int zoomLevel);

  /// Returns true if the rule matches the given tags and inddor level
  bool matches(List<Tag> tags, int indoorLevel);

  /// Checks the tags if the rule matches, does NOT take the indoorLevel into account.
  bool matchesTags(List<Tag> tags);

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    // tag not accepted by this rule.
    if (!matchesTags(pointOfInterest.tags)) return null;
    if (renderinstructionNodes.isNotEmpty) {
      // this rule supports the argument. Returns this zoomlevel range which is
      // the widest possible range.
      return zoomlevelRange;
    }

    ZoomlevelRange? result;
    for (var rule in subRules) {
      ZoomlevelRange? range = rule.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeOpenWay(List<Tag> tags) {
    if (!matchesTags(tags)) return null;

    if (renderinstructionOpenWays.isNotEmpty) return zoomlevelRange;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeClosedWay(List<Tag> tags) {
    if (!matchesTags(tags)) return null;

    if (renderinstructionClosedWays.isNotEmpty) return zoomlevelRange;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeClosedWay(tags);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  void onComplete() {
    for (int i = 0, n = subRules.length; i < n; ++i) {
      subRules.elementAt(i).onComplete();
    }
  }

  @override
  MapRectangle? searchForSymbolBoundary(String id) {
    Renderinstruction? result = renderinstructionNodes.firstWhereOrNull((element) => element is RenderinstructionSymbol && element.id == id);
    if (result != null) return (result as RenderinstructionSymbol).getBoundary();
    if (parent != null) return parent!.searchForSymbolBoundary(id);
    return null;
  }

  void matchNode(final int indoorLevel, List<Renderinstruction> matchingList, PointOfInterest pointOfInterest) {
    if (matches(pointOfInterest.tags, indoorLevel)) {
      matchingList.addAll(renderinstructionNodes);
      for (var element in subRules) {
        element.matchNode(indoorLevel, matchingList, pointOfInterest);
      }
    }
  }

  void matchOpenWay(Way way, Tile tile, List<Renderinstruction> matchingList) {
    if (matches(way.tags, tile.indoorLevel)) {
      matchingList.addAll(renderinstructionOpenWays);
      for (var element in subRules) {
        element.matchOpenWay(way, tile, matchingList);
      }
    }
  }

  void matchClosedWay(Way way, Tile tile, List<Renderinstruction> matchingList) {
    if (matches(way.tags, tile.indoorLevel)) {
      matchingList.addAll(renderinstructionClosedWays);
      for (var element in subRules) {
        element.matchClosedWay(way, tile, matchingList);
      }
    }
  }

  @override
  String toString() {
    //return 'Rule{zoomlevelRange: $zoomlevelRange, renderInstructionNodes: $renderinstructionNodes, renderInstructionOpenWays: $renderinstructionOpenWays, renderInstructionClosedWays: $renderinstructionClosedWays}';
    return 'Rule{zoomlevelRange: $zoomlevelRange, renderInstructionNodes: ${renderinstructionNodes.length}, renderInstructionOpenWays: ${renderinstructionOpenWays.length}, renderInstructionClosedWays: ${renderinstructionClosedWays.length}}';
  }
}

/////////////////////////////////////////////////////////////////////////////

class RuleVisitor {
  void apply(Rule r) {
    for (Rule subRule in r.subRules) {
      apply(subRule);
    }
  }
}
