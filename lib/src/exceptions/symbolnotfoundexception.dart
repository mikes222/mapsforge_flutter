class SymbolNotFoundException implements Exception {
  final String src;

  SymbolNotFoundException(this.src);

  @override
  String toString() {
    return 'SymbolNotFoundException{src: $src}';
  }
}
