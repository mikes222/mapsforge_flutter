import 'package:mapsforge_flutter/core.dart';

class Waypath {
  final List<ILatLong> _path;

  bool? _closed;

  // cached bounding box
  BoundingBox? _boundingBox;

  Waypath(this._path);

  int get length => _path.length;

  BoundingBox get boundingBox {
    if (_boundingBox != null) {
      return _boundingBox!;
    }
    _boundingBox = BoundingBox.fromLatLongs(_path);
    return _boundingBox!;
  }

  bool isClosedWay() {
    if (_closed != null) {
      return _closed!;
    }
    _closed = LatLongUtils.isClosedWay(_path);
    return _closed!;
  }

  ILatLong get first => _path.first;

  ILatLong get last => _path.last;

  List<ILatLong> sublist(int start, [int? end]) => _path.sublist(start, end);

  void insert(int index, ILatLong latLong) {
    _path.insert(index, latLong);
    _closed = null;
    _boundingBox = null;
  }

  void add(ILatLong latLong) {
    _path.add(latLong);
    _closed = null;
    _boundingBox = null;
  }

  void clear() {
    _path.clear();
    _closed = null;
    _boundingBox = null;
  }

  bool get isEmpty => _path.isEmpty;

  bool get isNotEmpty => _path.isNotEmpty;

  // for debugging purposes: return a copy of the path
  List<ILatLong> get path => _path; //List.from(_path);

  List<ILatLong> get pathForModification {
    _closed = null;
    _boundingBox = null;
    return _path;
  }
}
