/// Utility class providing helper methods for list operations.
/// 
/// This class contains static utility methods for common list operations
/// that are not available in the standard Dart libraries or need custom
/// implementations for specific use cases.
class ListHelper {
  /// Compares two lists for element-by-element equality.
  /// 
  /// This implementation is adapted from dart:collection for Flutter compatibility.
  /// Returns true if both lists are null, or if they are non-null with the same
  /// length and identical elements in the same order.
  /// 
  /// Note: Uses shallow equality comparison via [Object.==]. For deep equality
  /// of nested collections, consider using DeepCollectionEquality.
  /// 
  /// [a] First list to compare
  /// [b] Second list to compare
  /// Returns true if lists are equal, false otherwise
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
