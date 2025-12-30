import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/latlong_utils.dart';

/// A mutable container for a single path of a way, which is a list of `ILatLong` coordinates.
///
/// This class provides methods for manipulating the path, such as adding, inserting,
/// and removing points. It also caches properties like the bounding box and whether
/// the path is closed to improve performance.
class Waypath {
  final List<ILatLong> _path;

  /// cached marker if this way is a closed way
  bool? _closed;

  // cached bounding box
  BoundingBox? _boundingBox;

  /// Creates a new `Waypath` with the given [path].
  Waypath({required List<ILatLong> path}) : assert(path.isNotEmpty), _path = path;

  /// Creates a deep copy of this `Waypath`.
  Waypath clone() {
    Waypath result = Waypath(path: List.from(_path));
    result._closed = _closed;
    result._boundingBox = _boundingBox;
    return result;
  }

  /// Creates a new, empty `Waypath`.
  Waypath.empty() : _path = [], _closed = null;

  /// The number of points in the path.
  int get length => _path.length;

  /// The bounding box of the path.
  ///
  /// This property is cached for performance.
  BoundingBox get boundingBox {
    if (_boundingBox != null) {
      return _boundingBox!;
    }
    _boundingBox = BoundingBox.fromLatLongs(_path);
    return _boundingBox!;
  }

  /// Returns true if the path is a closed way (the first and last points are the same).
  ///
  /// This property is cached for performance.
  bool isClosedWay() {
    if (_closed != null) {
      return _closed!;
    }
    _closed = LatLongUtils.isClosedWay(_path);
    return _closed!;
  }

  /// The first point in the path.
  ILatLong get first => _path.first;

  /// The last point in the path.
  ILatLong get last => _path.last;

  /// Returns a new list containing a subset of the path.
  List<ILatLong> sublist(int start, [int? end]) => _path.sublist(start, end);

  /// Inserts a point at the given [index].
  void insert(int index, ILatLong latLong) {
    _path.insert(index, latLong);
    _closed = null;
    _boundingBox = null;
  }

  /// Inserts all points from the given iterable at the given [index].
  void insertAll(int index, Iterable<ILatLong> latLongs) {
    _path.insertAll(index, latLongs);
    _closed = null;
    _boundingBox = null;
  }

  /// Adds a point to the end of the path.
  void add(ILatLong latLong) {
    _path.add(latLong);
    _closed = null;
    _boundingBox = null;
  }

  /// Adds all points from the given iterable to the end of the path.
  void addAll(Iterable<ILatLong> latLongs) {
    _path.addAll(latLongs);
    _closed = null;
    _boundingBox = null;
  }

  /// Removes the point at the given [index].
  void removeAt(int index) {
    _path.removeAt(index);
    assert(_path.isNotEmpty);
    _closed = null;
    _boundingBox = null;
  }

  /// Removes all points from the path.
  void clear() {
    _path.clear();
    _closed = null;
    _boundingBox = null;
  }

  /// Returns true if the path is empty.
  bool get isEmpty => _path.isEmpty;

  /// Returns true if the path is not empty.
  bool get isNotEmpty => _path.isNotEmpty;

  /// A read-only view of the path.
  ///
  /// In debug mode, this returns an unmodifiable list to prevent accidental
  /// modifications.
  List<ILatLong> get path {
    List<ILatLong> result = _path;
    assert(() {
      // in debug mode return an unmodifiable list to find violations
      result = List.unmodifiable(result);
      return true;
    }());
    return result;
  }

  /// Returns the underlying list of points for modification.
  ///
  /// Accessing this property clears the cached bounding box and closed status,
  /// as they will need to be recalculated.
  List<ILatLong> get pathForModification {
    _closed = null;
    _boundingBox = null;
    return _path;
  }

  /// Returns true if the path contains the given [latLong].
  bool contains(ILatLong latLong) {
    if (_boundingBox != null && !_boundingBox!.containsLatLong(latLong)) {
      return false;
    }
    return LatLongUtils.contains(_path, latLong);
  }

  @override
  String toString() {
    return 'Waypath{_path: ${_path.length} items, _closed: $_closed, _boundingBox: $_boundingBox}';
  }
}
