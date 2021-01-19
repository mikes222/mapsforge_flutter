class SymbolNotFoundException implements Exception {
  final String src;

  SymbolNotFoundException(this.src) : assert(src != null);

  @override
  String toString() {
    return 'SymbolNotFoundException{src: $src}';
  }
}
