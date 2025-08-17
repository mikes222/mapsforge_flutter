import 'package:mapsforge_flutter/core.dart';

class Waypath {
  final List<ILatLong> _path;

  /// cached marker if this way is a closed way
  bool? _closed;

  // cached bounding box
  BoundingBox? _boundingBox;

  Waypath(this._path) : assert(_path.isNotEmpty);

  Waypath clone() {
    Waypath result = Waypath(List.from(_path));
    result._closed = _closed;
    result._boundingBox = _boundingBox;
    return result;
  }

  Waypath.empty()
      : _path = [],
        _closed = false;

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

  void insertAll(int index, Iterable<ILatLong> latLongs) {
    _path.insertAll(index, latLongs);
    _closed = null;
    _boundingBox = null;
  }

  void add(ILatLong latLong) {
    _path.add(latLong);
    _closed = null;
    _boundingBox = null;
  }

  void addAll(Iterable<ILatLong> latLongs) {
    _path.addAll(latLongs);
    _closed = null;
    _boundingBox = null;
  }

  void removeAt(int index) {
    _path.removeAt(index);
    assert(_path.isNotEmpty);
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
  List<ILatLong> get path {
    List<ILatLong> result = _path;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  /// Returns the path and clears the cached properties so that we have to recreate them next time.
  List<ILatLong> get pathForModification {
    _closed = null;
    _boundingBox = null;
    return _path;
  }

  @override
  String toString() {
    return 'Waypath{_path: ${_path.length} items, _closed: $_closed, _boundingBox: $_boundingBox}';
  }
}
