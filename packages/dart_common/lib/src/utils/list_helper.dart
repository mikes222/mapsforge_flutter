class ListHelper {
  /// copied from collections.dart (part of dart:collection), but only for flutter
  /// Compares two lists for element-by-element equality.
  ///
  /// Returns true if the lists are both null, or if they are both non-null, have
  /// the same length, and contain the same members in the same order. Returns
  /// false otherwise.
  ///
  /// If the elements are maps, lists, sets, or other collections/composite
  /// objects, then the contents of those elements are not compared element by
  /// element unless their equality operators ([Object.==]) do so. For checking
  /// deep equality, consider using the [DeepCollectionEquality] class.
  ///
  /// See also:
  ///
  ///  * [setEquals], which does something similar for sets.
  ///  * [mapEquals], which does something similar for maps.
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    if (identical(a, b)) {
      return true;
    }
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
