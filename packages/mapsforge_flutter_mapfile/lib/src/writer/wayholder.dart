import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// Holds one way and its tags
class Wayholder {
  final TagholderCollection tagholderCollection;

  /// This way is already merged with another way and hence should not be written to the file.
  bool mergedWithOtherWay = false;

  /// Innner ways of the master (normally they are all closed)
  final List<Waypath> _inner = [];

  // outer ways which are closed
  final List<Waypath> _closedOuters = [];

  /// PBF supports relations with multiple outer ways. Mapfile requires to
  /// store this outer ways as additional Way data blocks and split it into
  /// several ways - all with the same way properties - when reading the file.
  final List<Waypath> _openOuters = [];

  /// The position of the area label (may be null). Only relations can have labelPositions.
  ILatLong? labelPosition;

  /// Cache for the bounding box of the way
  BoundingBox? _boundingBox;

  // The master path. It will be extracted from _closedOuters or _openOuters shortly before writing the data to the file.
  Waypath? _master;

  Wayholder({required this.tagholderCollection});

  Wayholder cloneWith({List<Waypath>? inner, List<Waypath>? closedOuters, List<Waypath>? openOuters}) {
    Wayholder result = Wayholder(tagholderCollection: tagholderCollection);
    result._master = _master?.clone();
    result._inner.addAll(inner ?? _inner.map((toElement) => toElement.clone()).toList());
    result.closedOutersAddAll(closedOuters ?? _closedOuters.map((toElement) => toElement.clone()).toList());
    result._openOuters.addAll(openOuters ?? _openOuters.map((toElement) => toElement.clone()).toList());
    result.labelPosition = labelPosition;
    result._boundingBox = _boundingBox;
    return result;
  }

  List<Waypath> get innerRead {
    List<Waypath> result = _inner;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  List<Waypath> get innerWrite {
    _boundingBox = null;
    return _inner;
  }

  void innerAdd(Waypath waypath) {
    assert(waypath.length >= 2);
    _boundingBox = null;
    _inner.add(waypath);
  }

  void innerAddAll(List<Waypath> waypaths) {
    assert(!waypaths.any((waypath) => waypath.length < 2));
    _boundingBox = null;
    _inner.addAll(waypaths);
  }

  bool innerIsNotEmpty() {
    return _inner.isNotEmpty;
  }

  bool innerIsEmpty() {
    return _inner.isEmpty;
  }

  List<Waypath> get closedOutersRead {
    List<Waypath> result = _closedOuters;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  List<Waypath> get openOutersRead {
    List<Waypath> result = _openOuters;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  List<Waypath> get closedOutersWrite {
    _boundingBox = null;
    return _closedOuters;
  }

  void closedOutersAdd(Waypath waypath) {
    assert(waypath.length > 2);
    assert(
      waypath.isClosedWay(),
      "way must be closed ${waypath.length} ${waypath.first} - ${waypath.last} ${waypath.first.latitude - waypath.last.latitude} / ${waypath.first.longitude - waypath.last.longitude}",
    );
    if (!LatLongUtils.isEqual(waypath.first, waypath.last)) {
      waypath.removeAt(waypath.length - 1);
      waypath.add(LatLong(waypath.first.latitude, waypath.first.longitude));
    }
    _boundingBox = null;
    _closedOuters.add(waypath);
  }

  void closedOutersAddAll(List<Waypath> waypaths) {
    assert(!waypaths.any((waypath) => !waypath.isClosedWay()));
    assert(!waypaths.any((waypath) => waypath.length <= 2));
    _boundingBox = null;
    for (var waypath in waypaths) {
      if (!LatLongUtils.isEqual(waypath.first, waypath.last)) {
        waypath.removeAt(waypath.length - 1);
        waypath.add(LatLong(waypath.first.latitude, waypath.first.longitude));
      }
    }
    _closedOuters.addAll(waypaths);
  }

  void closedOutersRemove(Waypath waypath) {
    bool ok = _closedOuters.remove(waypath);
    if (ok) {
      _boundingBox = null;
    }
  }

  bool closedOutersIsNotEmpty() {
    return _closedOuters.isNotEmpty;
  }

  bool closedOutersIsEmpty() {
    return _closedOuters.isEmpty;
  }

  int closedOutersLength() {
    return _closedOuters.length;
  }

  List<Waypath> get openOutersWrite {
    _boundingBox = null;
    return _openOuters;
  }

  void openOutersAdd(Waypath waypath) {
    assert(
      !waypath.isClosedWay(),
      "way must not be closed ${waypath.length} ${waypath.first} - ${waypath.last} ${waypath.first.latitude - waypath.last.latitude} / ${waypath.first.longitude - waypath.last.longitude}",
    );
    assert(waypath.length >= 2);
    _boundingBox = null;
    _openOuters.add(waypath);
  }

  void openOutersAddAll(List<Waypath> waypaths) {
    assert(!waypaths.any((waypath) => waypath.length < 2));
    assert(!waypaths.any((waypath) => waypath.isClosedWay()));
    _boundingBox = null;
    _openOuters.addAll(waypaths);
  }

  void openOutersRemove(Waypath waypath) {
    bool ok = _openOuters.remove(waypath);
    if (ok) {
      _boundingBox = null;
    }
  }

  bool openOutersIsNotEmpty() {
    return _openOuters.isNotEmpty;
  }

  bool openOutersIsEmpty() {
    return _openOuters.isEmpty;
  }

  int openOutersLength() {
    return _openOuters.length;
  }

  bool mayMoveToClosed(Waypath waypath) {
    assert(_openOuters.contains(waypath));
    if (waypath.isClosedWay()) {
      openOutersRemove(waypath);
      closedOutersAdd(waypath);
      return true;
    }
    return false;
  }

  BoundingBox get boundingBoxCached {
    if (_boundingBox != null) return _boundingBox!;
    assert(_closedOuters.isNotEmpty || _openOuters.isNotEmpty || _master != null, "No bounding box available for ${toStringWithoutNames()}");
    _boundingBox = _master != null
        ? _master!.boundingBox
        : _closedOuters.isNotEmpty
        ? _closedOuters.first.boundingBox
        : _openOuters.first.boundingBox;
    for (var action in _closedOuters) {
      _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox);
    }
    for (var action in _openOuters) {
      _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox);
    }
    return _boundingBox!;
  }

  bool hasTag(String key) {
    return tagholderCollection.hasTag(key);
  }

  bool hasTagValue(String key, String value) {
    return tagholderCollection.hasTagValue(key, value);
  }

  String? getTag(String key) {
    return tagholderCollection.getTag(key);
  }

  /// moves the inner ways to the outer ways if no outer ways exists anymore
  void moveInnerToOuter() {
    if (innerRead.isNotEmpty && openOutersRead.isEmpty && closedOutersRead.isEmpty) {
      for (var inner in innerRead) {
        if (inner.isClosedWay()) {
          closedOutersAdd(inner);
        } else {
          openOutersAdd(inner);
        }
      }
      innerWrite.clear();
    }
  }

  Waypath extractMaster() {
    if (_master != null) {
      print("Master already extracted");
      return _master!;
    }
    if (_closedOuters.isNotEmpty) {
      _master = _closedOuters.reduce((a, b) => a.length > b.length ? a : b);
      assert(_master!.length >= 2);
      _closedOuters.remove(_master);
      return _master!;
    }
    _master = _openOuters.reduce((a, b) => a.length > b.length ? a : b);
    assert(_master!.length >= 2);
    _openOuters.remove(_master);
    return _master!;
  }

  int nodeCount() {
    return (_closedOuters.fold(0, (idx, combine) => idx + combine.length) +
                _openOuters.fold(0, (idx, combine) => idx + combine.length) +
                _inner.fold(0, (idx, combine) => idx + combine.length))
            .toInt() +
        (_master?.length ?? 0);
  }

  int pathCount() {
    return _closedOuters.length + _openOuters.length + _inner.length + (_master != null ? 1 : 0);
  }

  @override
  String toString() {
    return 'Wayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, labelPosition: $labelPosition, tagholderCollection: $tagholderCollection}';
  }

  String toStringWithoutNames() {
    return 'Wayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, labelPosition: $labelPosition, tagholderCollection: ${tagholderCollection.printTagsWithoutNames()}';
  }
}
