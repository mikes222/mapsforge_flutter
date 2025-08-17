import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/tagholder_mixin.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one way and its tags
class Wayholder with TagholderMixin {
  int tileBitmask = 0xffff;

  // The master path. It will be extracted from _closedOuters or _openOuters shortly before writing the data to the file.
  Waypath? _master;

  /// Innner ways of the master (normally they are all closed)
  List<Waypath> _inner = [];

  // outer ways which are closed
  List<Waypath> _closedOuters = [];

  /// PBF supports relations with multiple outer ways. Mapfile requires to
  /// store this outer ways as additional Way data blocks and split it into
  /// several ways - all with the same way properties - when reading the file.
  List<Waypath> _openOuters = [];

  /// This way is already merged with another way and hence should not be written to the file.
  bool mergedWithOtherWay = false;

  /// The position of the area label (may be null).
  ILatLong? labelPosition;

  /// The tags of this way.
  List<Tag> tags = [];

  /// The layer of this way + 5 (to avoid negative values).
  int layer = 0;

  /// Cache for the bounding box of the way
  BoundingBox? _boundingBox;

  Wayholder() {}

  /// Creates a new wayholder from a existing way. Note that the existing way may NOT contain any path (if created from a OsmRelation)
  Wayholder.fromWay(Way way) {
    _inner = way.latLongs.skip(1).map((toElement) => Waypath(toElement)).toList();
    _closedOuters = [];
    _openOuters = [];
    if (way.latLongs.isNotEmpty) {
      if (LatLongUtils.isClosedWay(way.latLongs[0])) {
        _closedOuters.add(Waypath(way.latLongs[0]));
      } else {
        _openOuters.add(Waypath(way.latLongs[0]));
      }
    }

    tags = way.tags;
    layer = way.layer;
    labelPosition = way.labelPosition;
  }

  Wayholder cloneWith({List<Waypath>? inner, List<Waypath>? closedOuters, List<Waypath>? openOuters}) {
    Wayholder result = Wayholder();
    result._closedOuters = closedOuters ?? this._closedOuters.map((toElement) => toElement.clone()).toList();
    result._openOuters = openOuters ?? this._openOuters.map((toElement) => toElement.clone()).toList();
    result._inner = inner ?? this._inner.map((toElement) => toElement.clone()).toList();
    result.tileBitmask = this.tileBitmask;
    result.labelPosition = this.labelPosition;
    result.tags = List.from(this.tags);
    result.layer = this.layer;
    result.mergedWithOtherWay = this.mergedWithOtherWay;
    result.featureElevation = this.featureElevation;
    result.featureHouseNumber = this.featureHouseNumber;
    result.featureName = this.featureName;
    result.featureRef = this.featureRef;
    result.languagesPreference = this.languagesPreference;
    result.tagholders = List.from(this.tagholders);
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

  List<Waypath> get innerWrite {
    _boundingBox = null;
    return _inner;
  }

  void innerAddAll(List<Waypath> waypaths) {
    _boundingBox = null;
    _inner.addAll(waypaths);
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

  List<Waypath> get openOutersWrite {
    _boundingBox = null;
    return _openOuters;
  }

  void openOutersAdd(Waypath waypath) {
    assert(!waypath.isClosedWay());
    _boundingBox = null;
    _openOuters.add(waypath);
  }

  void openOutersAddAll(List<Waypath> waypaths) {
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

  bool mayMoveToClosed(Waypath waypath) {
    assert(_openOuters.contains(waypath));
    if (waypath.isClosedWay()) {
      _openOuters.remove(waypath);
      _closedOuters.add(waypath);
      return true;
    }
    return false;
  }

  BoundingBox get boundingBoxCached {
    if (_boundingBox != null) return _boundingBox!;
    assert(_closedOuters.isNotEmpty || _openOuters.isNotEmpty || _master != null, "No bounding box available for ${this.toStringWithoutNames()}");
    _boundingBox = _master != null
        ? _master!.boundingBox
        : _closedOuters.isNotEmpty
            ? _closedOuters.first.boundingBox
            : _openOuters.first.boundingBox;
    _closedOuters.forEach((action) => _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox));
    _openOuters.forEach((action) => _boundingBox = _boundingBox!.extendBoundingBox(action.boundingBox));
    return _boundingBox!;
  }

  bool hasTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  bool hasTagValue(String key, String value) {
    return tags.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  String? getTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  /// A tile on zoom level <i>z</i> has exactly 16 sub tiles on zoom level <i>z+2</i>. For each of these 16 sub tiles
  /// it is analyzed if the given way needs to be included. The result is represented as a 16 bit short value. Each bit
  /// represents one of the 16 sub tiles. A bit is set to 1 if the sub tile needs to include the way. Representation is
  /// row-wise.
  ///
  /// @param geometry           the geometry which is analyzed
  /// @param tile               the tile which is split into 16 sub tiles
  /// @param enlargementInMeter amount of pixels that is used to enlarge the bounding box of the way and the tiles in the mapping
  ///                           process
  /// @return a 16 bit short value that represents the information which of the sub tiles needs to include the way
  void _computeBitmask(Tile tile) {
    List<Tile> subtiles = tile.getGrandchilds();

    tileBitmask = 0;
    int tileCounter = 1 << 15;
    BoundingBox boundingBox = boundingBoxCached;
    for (Tile subtile in subtiles) {
      if (subtile.getBoundingBox().intersects(boundingBox) ||
          subtile.getBoundingBox().containsBoundingBox(boundingBox) ||
          boundingBox.containsBoundingBox(subtile.getBoundingBox())) {
        tileBitmask |= tileCounter;
      }
      tileCounter = tileCounter >> 1;
    }
    // if (tile.zoomLevel <= 4) {
    //   print("$tile 0x${tileBitmask.toRadixString(16)} for ${this.toStringWithoutNames()} $boundingBoxCached");
    //   _closedOuters.where((test) => test.length < 3).forEach((test) => print("  test in compute: $test ${test.path}"));
    // }
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    if (languagesPreference != null) super.languagesPreference.addAll(languagesPreference.split(","));
    analyzeTags(tags, tagholders);
  }

  /// moves the inner ways to the outer ways if no outer ways exists anymore
  void moveInnerToOuter() {
    if (innerRead.isNotEmpty && openOutersRead.isEmpty && closedOutersRead.isEmpty) {
      for (var inner in innerRead) {
        if (inner.isClosedWay()) {
          closedOutersWrite.add(inner);
        } else {
          openOutersWrite.add(inner);
        }
      }
      innerWrite.clear();
    }
  }

  /// can be done when the tags are sorted
  Writebuffer writeWaydata(bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    _computeBitmask(tile);
    Writebuffer writebuffer3 = Writebuffer();
    _writeWaySignature(debugFile, writebuffer3);
    Writebuffer writebuffer = _writeWayPropertyAndWayData(tileLatitude, tileLongitude);
    // get the size of the way (VBE-U)
    writebuffer3.appendUnsignedInt(writebuffer.length);
    writebuffer3.appendWritebuffer(writebuffer);
    return writebuffer3;
  }

  void _writeWaySignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("---WayStart${hashCode}---".padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  Waypath _extractMaster() {
    if (_closedOuters.isNotEmpty) {
      _master = _closedOuters.reduce((a, b) => a.length > b.length ? a : b);
      _closedOuters.remove(_master);
      return _master!;
    }
    _master = _openOuters.reduce((a, b) => a.length > b.length ? a : b);
    _openOuters.remove(_master);
    return _master!;
  }

  Writebuffer _writeWayPropertyAndWayData(double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();

    /// A tile on zoom level z is made up of exactly 16 sub tiles on zoom level z+2
    // for each sub tile (row-wise, left to right):
    // 1 bit that represents a flag whether the way is relevant for the sub tile
    // Special case: coastline ways must always have all 16 bits set.
    writebuffer.appendUInt2(tileBitmask);

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (tagholders.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    writeTags(writebuffer);

    Waypath _master = _extractMaster();

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (featureHouseNumber != null) featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (featureRef != null) featureByte |= MapfileHelper.WAY_FEATURE_REF;
    bool featureLabelPosition = labelPosition != null;
    if (featureLabelPosition) featureByte |= MapfileHelper.WAY_FEATURE_LABEL_POSITION;
    // number of way data blocks or false if we have only 1
    bool featureWayDataBlocksByte = _openOuters.isNotEmpty | _closedOuters.isNotEmpty;
    if (featureWayDataBlocksByte) featureByte |= MapfileHelper.WAY_FEATURE_DATA_BLOCKS_BYTE;

    bool? expectDouble = null;
    // less than 10 coordinates? Use singe encoding
    int sum = nodeCount();
    if (sum <= 30)
      expectDouble = false;
    else if (sum >= 100) expectDouble = true;

    Writebuffer singleWritebuffer = Writebuffer();
    if (expectDouble == null || !expectDouble) {
      _writeSingleDeltaEncoding(singleWritebuffer, [_master]..addAll(_inner), tileLatitude, tileLongitude);
      _closedOuters.forEach((action) => _writeSingleDeltaEncoding(singleWritebuffer, [action], tileLatitude, tileLongitude));
      _openOuters.forEach((action) => _writeSingleDeltaEncoding(singleWritebuffer, [action], tileLatitude, tileLongitude));
    }

    Writebuffer doubleWritebuffer = Writebuffer();
    if (expectDouble == null || expectDouble) {
      _writeDoubleDeltaEncoding(doubleWritebuffer, [_master]..addAll(_inner), tileLatitude, tileLongitude);
      _closedOuters.forEach((action) => _writeDoubleDeltaEncoding(doubleWritebuffer, [action], tileLatitude, tileLongitude));
      _openOuters.forEach((action) => _writeDoubleDeltaEncoding(doubleWritebuffer, [action], tileLatitude, tileLongitude));
    }

    bool featureWayDoubleDeltaEncoding = singleWritebuffer.length == 0
        ? true
        : doubleWritebuffer.length == 0
            ? false
            : doubleWritebuffer.length < singleWritebuffer.length;
    if (featureWayDoubleDeltaEncoding) featureByte |= MapfileHelper.WAY_FEATURE_DOUBLE_DELTA_ENCODING;

    writebuffer.appendInt1(featureByte);

    if (featureName != null) {
      writebuffer.appendString(featureName!);
    }
    if (featureHouseNumber != null) {
      writebuffer.appendString(featureHouseNumber!);
    }
    if (featureRef != null) {
      writebuffer.appendString(featureRef!);
    }

    if (featureLabelPosition) {
      ILatLong first = _master.first;
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(labelPosition!.latitude - first.latitude));
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(labelPosition!.longitude - first.longitude));
    }

    if (featureWayDataBlocksByte) {
      writebuffer.appendUnsignedInt(_closedOuters.length + _openOuters.length + 1);
    }

    if (featureWayDoubleDeltaEncoding)
      writebuffer.appendWritebuffer(doubleWritebuffer);
    else
      writebuffer.appendWritebuffer(singleWritebuffer);

    return writebuffer;
  }

  /// Way data block
  void _writeSingleDeltaEncoding(Writebuffer writebuffer, List<Waypath> waypaths, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    if (waypaths.isEmpty) return;
    assert(waypaths.length <= 32767, "${waypaths.length} too much for ${this.toStringWithoutNames()}");
    writebuffer.appendUnsignedInt(waypaths.length);
    for (Waypath waypath in waypaths) {
      assert(waypath.length >= 2, "${waypath.length} too little for ${this.toStringWithoutNames()}");
      assert(waypath.length <= 32767, "${waypath.length} too much for ${this.toStringWithoutNames()}");
      // amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waypath.length);
      bool first = true;
      double previousLatitude = 0;
      double previousLongitude = 0;
      for (ILatLong coordinate in waypath.path) {
        if (first) {
          previousLatitude = coordinate.latitude - tileLatitude;
          previousLongitude = coordinate.longitude - tileLongitude;
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(previousLatitude));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(previousLongitude));
          first = false;
        } else {
          double currentLatitude = coordinate.latitude - tileLatitude;
          double currentLongitude = coordinate.longitude - tileLongitude;

          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(currentLatitude - previousLatitude));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(currentLongitude - previousLongitude));

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;
        }
      }
    }
  }

  /// Way data block
  void _writeDoubleDeltaEncoding(Writebuffer writebuffer, List<Waypath> waypaths, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    if (waypaths.isEmpty) return;
    assert(waypaths.length <= 32767, "${waypaths.length} too much for ${this.toStringWithoutNames()}");
    writebuffer.appendUnsignedInt(waypaths.length);
    for (Waypath waypath in waypaths) {
      assert(waypath.length >= 2, "${waypath.length} too little for ${this.toStringWithoutNames()}");
      assert(waypath.length <= 32767, "${waypath.length} too much for ${this.toStringWithoutNames()}");
// amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waypath.length);
      bool first = true;
      // I had to switch to int because I had rounding errors which summed up so that a closed waypoint was not recognized as closed anymore
      int previousLatitude = 0;
      int previousLongitude = 0;
      int previousLatitudeDelta = 0;
      int previousLongitudeDelta = 0;
      for (ILatLong coordinate in waypath.path) {
        if (first) {
          previousLatitude = LatLongUtils.degreesToMicrodegrees(coordinate.latitude - tileLatitude);
          previousLongitude = LatLongUtils.degreesToMicrodegrees(coordinate.longitude - tileLongitude);
          writebuffer.appendSignedInt(previousLatitude);
          writebuffer.appendSignedInt(previousLongitude);
          first = false;
        } else {
          int currentLatitude = LatLongUtils.degreesToMicrodegrees(coordinate.latitude - tileLatitude);
          int currentLongitude = LatLongUtils.degreesToMicrodegrees(coordinate.longitude - tileLongitude);

          int deltaLatitude = currentLatitude - previousLatitude;
          int deltaLongitude = currentLongitude - previousLongitude;

          writebuffer.appendSignedInt(deltaLatitude - previousLatitudeDelta);
          writebuffer.appendSignedInt(deltaLongitude - previousLongitudeDelta);

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;

          previousLatitudeDelta = deltaLatitude;
          previousLongitudeDelta = deltaLongitude;
        }
      }
    }
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
    return 'Wayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, mergedWithOtherWay: $mergedWithOtherWay, labelPosition: $labelPosition, tags: $tags}';
  }

  String toStringWithoutNames() {
    return 'Wayholder{closedOuters: ${LatLongUtils.printWaypaths(_closedOuters)}, openOuters: ${LatLongUtils.printWaypaths(_openOuters)}, inner: ${LatLongUtils.printWaypaths(_inner)}, mergedWithOtherWay: $mergedWithOtherWay, labelPosition: $labelPosition, tags: ${tags.where((test) => test.key?.startsWith("name:") == false && test.key?.startsWith("official_name") == false).map((toElement) => "${toElement.key}=${toElement.value}").join(",")}';
  }
}
