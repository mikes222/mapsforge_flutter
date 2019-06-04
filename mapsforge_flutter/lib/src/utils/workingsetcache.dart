import 'package:dcache/dcache.dart';

/**
 * Cache that maintains a working set of elements in the cache, given to it by
 * setWorkingSet(Set<K>) in addition to other elements which are kept on a LRU
 * basis.
 *
 * @param <K> the type of the map key, see {@link java.util.Map}.
 * @param <V> the type of the map value, see {@link java.util.Map}.
 */
class WorkingSetCache<K, V> extends SimpleCache<K, V> {
  WorkingSetCache(int capacity) : super(storage: new SimpleStorage(size: capacity));

  /**
   * Sets the current working set, ensuring that elements in this working set
   * will not be ejected in the near future.
   *
   * @param workingSet set of K that makes up the current working set.
   */
  void setWorkingSet(Set<K> workingSet) {
    //synchronized(workingSet) {
    for (K key in workingSet) {
      this.get(key);
    }
    //}
  }

  void put(K key, V value) {
    set(key, value);
  }

  int get capacity => storage.capacity;

  List<CacheEntry<K, V>> get values => storage.values;
}
