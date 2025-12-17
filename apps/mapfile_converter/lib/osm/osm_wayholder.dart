import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class OsmWayholder {
  final TagCollection tagCollection;

  /// The layer of this way + 5 (to avoid negative values).
  final int layer;

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

  Wayholder? _wayholder;

  OsmWayholder({required this.tagCollection, required this.layer});

  bool hasTagValue(String key, String value) {
    return tagCollection.hasTagValue(key, value);
  }

  bool hasTag(String key) {
    return tagCollection.hasTag(key);
  }

  int nodeCount() {
    return (_closedOuters.fold(0, (idx, combine) => idx + combine.length) +
            _openOuters.fold(0, (idx, combine) => idx + combine.length) +
            _inner.fold(0, (idx, combine) => idx + combine.length))
        .toInt();
  }

  BoundingBox get boundingBoxCached {
    if (_boundingBox != null) return _boundingBox!;
    assert(_closedOuters.isNotEmpty || _openOuters.isNotEmpty, "No bounding box available for ${toStringWithoutNames()}");
    _boundingBox = _closedOuters.isNotEmpty ? _closedOuters.first.boundingBox : _openOuters.first.boundingBox;
    for (var action in _closedOuters) {
      _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox);
    }
    for (var action in _openOuters) {
      _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox);
    }
    return _boundingBox!;
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

  List<Waypath> get closedOutersRead {
    List<Waypath> result = _closedOuters;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  bool closedOutersIsNotEmpty() {
    return _closedOuters.isNotEmpty;
  }

  List<Waypath> get closedOutersWrite {
    _boundingBox = null;
    return _closedOuters;
  }

  void closedOutersAdd(Waypath waypath) {
    assert(waypath.isClosedWay());
    assert(waypath.length > 2);
    _boundingBox = null;
    _closedOuters.add(waypath);
  }

  void closedOutersAddAll(List<Waypath> waypaths) {
    assert(!waypaths.any((waypath) => !waypath.isClosedWay()));
    assert(!waypaths.any((waypath) => waypath.length <= 2));
    _boundingBox = null;
    _closedOuters.addAll(waypaths);
  }

  void closedOutersRemove(Waypath waypath) {
    bool ok = _closedOuters.remove(waypath);
    if (ok) {
      _boundingBox = null;
    }
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

  bool openOutersIsNotEmpty() {
    return _openOuters.isNotEmpty;
  }

  List<Waypath> get openOutersWrite {
    _boundingBox = null;
    return _openOuters;
  }

  void openOutersAdd(Waypath waypath) {
    assert(!waypath.isClosedWay());
    assert(waypath.length >= 2);
    _boundingBox = null;
    _openOuters.add(waypath);
  }

  void openOutersAddAll(List<Waypath> waypaths) {
    assert(!waypaths.any((waypath) => waypath.isClosedWay()));
    assert(!waypaths.any((waypath) => waypath.length < 2));
    _boundingBox = null;
    _openOuters.addAll(waypaths);
  }

  void openOutersRemove(Waypath waypath) {
    bool ok = _openOuters.remove(waypath);
    if (ok) {
      _boundingBox = null;
    }
  }

  /// moves the inner ways to the outer ways if no outer ways exists anymore
  void moveInnerToOuter() {
    if (innerRead.isNotEmpty && _openOuters.isEmpty && _closedOuters.isEmpty) {
      for (var inner in innerRead) {
        if (inner.isClosedWay()) {
          _closedOuters.add(inner);
        } else {
          _openOuters.add(inner);
        }
      }
      _inner.clear();
    }
  }

  bool mayMoveToClosed(Waypath waypath) {
    assert(_openOuters.contains(waypath));
    assert(waypath.length >= 2);
    if (waypath.isClosedWay()) {
      _openOuters.remove(waypath);
      _closedOuters.add(waypath);
      return true;
    }
    return false;
  }

  List<Waypath> get innerWrite {
    _boundingBox = null;
    return _inner;
  }

  OsmWayholder cloneWith({List<Waypath>? inner, List<Waypath>? closedOuters, List<Waypath>? openOuters}) {
    OsmWayholder result = OsmWayholder(tagCollection: tagCollection.clone(), layer: layer);
    result._closedOuters.addAll(closedOuters ?? _closedOuters.map((toElement) => toElement.clone()).toList());
    result._openOuters.addAll(openOuters ?? _openOuters.map((toElement) => toElement.clone()).toList());
    result._inner.addAll(inner ?? _inner.map((toElement) => toElement.clone()).toList());
    result.mergedWithOtherWay = mergedWithOtherWay;
    result.labelPosition = labelPosition;
    // result.tileBitmask = tileBitmask;
    // result.featureElevation = featureElevation;
    // result.featureHouseNumber = featureHouseNumber;
    // result.featureName = featureName;
    // result.featureRef = featureRef;
    // result.languagesPreference = languagesPreference;
    return result;
  }

  Wayholder convertToWayholder() {
    if (_wayholder != null) return _wayholder!;
    Wayholder wayholder = Wayholder(tags: tagCollection);
    wayholder.layer = layer;
    wayholder.labelPosition = labelPosition;
    wayholder.innerAddAll(innerRead);
    wayholder.closedOutersAddAll(closedOutersRead);
    wayholder.openOutersAddAll(openOutersRead);
    // since we create copies via isolates later on we extract the master - which is expensive - now
    // walking through the code I am not sure if this really is a good idea. The filter/reduce algorithm would not work with master.
    //wayholder.extractMaster();
    _wayholder = wayholder;
    return wayholder;
  }

  @override
  String toString() {
    return 'OsmWayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, mergedWithOtherWay: $mergedWithOtherWay, tags: $tagCollection}';
  }

  String toStringWithoutNames() {
    return 'OsmWayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, mergedWithOtherWay: $mergedWithOtherWay, tags: ${tagCollection.printTagsWithoutNames()}';
  }
}
