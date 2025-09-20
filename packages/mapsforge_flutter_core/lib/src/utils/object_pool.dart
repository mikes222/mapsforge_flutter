/// A simple object pool to reduce memory allocations and garbage collection pressure.
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;

  /// Creates a new `ObjectPool`.
  ///
  /// [factory] A function that creates new objects for the pool.
  /// [reset] An optional function that resets an object before it is returned to the pool.
  /// [maxSize] The maximum number of objects to store in the pool.
  ObjectPool({required T Function() factory, void Function(T)? reset, int maxSize = 50}) : _factory = factory, _reset = reset, _maxSize = maxSize;

  /// Acquires an object from the pool. If the pool is empty, a new object is
  /// created using the factory.
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return _factory();
  }

  /// Releases an object back to the pool.
  ///
  /// If the pool is full, the object is discarded and will be garbage collected.
  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
    // If pool is full, let object be garbage collected
  }

  /// Clears all objects from the pool.
  void clear() {
    _pool.clear();
  }

  /// Returns a map with statistics about the pool.
  Map<String, int> getStats() {
    return {'poolSize': _pool.length, 'maxSize': _maxSize};
  }
}
