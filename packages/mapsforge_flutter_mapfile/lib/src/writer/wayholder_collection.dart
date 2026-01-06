import 'dart:collection';

import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// A helper class to hold all ways for a specific zoom level during the
/// sub-file creation process.
class WayholderCollection implements IWayholderCollection {
  final Queue<Wayholder> _wayholders = Queue();

  WayholderCollection();

  @override
  Future<int> nodeCount() async {
    int result = 0;
    for (var wayholder in _wayholders) {
      result += wayholder.nodeCount();
    }
    return result;
  }

  @override
  Future<int> pathCount() async {
    int result = 0;
    for (var wayholder in _wayholders) {
      result += wayholder.pathCount();
    }
    return result;
  }

  @override
  bool get isEmpty => _wayholders.isEmpty;

  @override
  int get length => _wayholders.length;

  @override
  Future<void> forEach(void Function(Wayholder wayholder) action) async {
    for (var wayholder in _wayholders) {
      action(wayholder);
    }
  }

  @override
  Future<void> removeWhere(bool Function(Wayholder wayholder) test) async {
    _wayholders.removeWhere(test);
  }

  @override
  void add(Wayholder wayholder) {
    assert(wayholder.openOutersRead.isNotEmpty || wayholder.closedOutersRead.isNotEmpty);
    _wayholders.add(wayholder);
  }

  @override
  void addAll(Iterable<Wayholder> wayholders) {
    for (var test in wayholders) {
      assert(test.openOutersRead.isNotEmpty || test.closedOutersRead.isNotEmpty);
    }
    _wayholders.addAll(wayholders);
  }

  @override
  Future<void> freeRessources() async {}

  @override
  Future<void> dispose() async {
    _wayholders.clear();
  }
}
