/// An exception that is thrown when a symbol cannot be found.
class SymbolNotFoundException implements Exception {
  final String src;

  /// Creates a new `SymbolNotFoundException`.
  SymbolNotFoundException(this.src);

  @override
  String toString() {
    return 'SymbolNotFoundException{src: $src}';
  }
}
