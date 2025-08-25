/// A simple object pool to reduce memory allocations
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;
  
  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 50,
  }) : _factory = factory, _reset = reset, _maxSize = maxSize;
  
  /// Get an object from the pool or create a new one
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return _factory();
  }
  
  /// Return an object to the pool
  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
    // If pool is full, let object be garbage collected
  }
  
  /// Clear the pool
  void clear() {
    _pool.clear();
  }
  
  /// Get pool statistics
  Map<String, int> getStats() {
    return {
      'poolSize': _pool.length,
      'maxSize': _maxSize,
    };
  }
}

/// Pool manager for commonly used objects
class PoolManager {
  static final PoolManager _instance = PoolManager._internal();
  factory PoolManager() => _instance;
  PoolManager._internal();
  
  final Map<Type, ObjectPool> _pools = {};
  
  /// Register a pool for a specific type
  void registerPool<T>(ObjectPool<T> pool) {
    _pools[T] = pool;
  }
  
  /// Get a pool for a specific type
  ObjectPool<T>? getPool<T>() {
    return _pools[T] as ObjectPool<T>?;
  }
  
  /// Clear all pools
  void clearAll() {
    for (final pool in _pools.values) {
      pool.clear();
    }
  }
}
