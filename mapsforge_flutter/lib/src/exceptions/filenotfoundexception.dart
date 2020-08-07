class FileNotFoundException implements Exception {
  final String filename;

  FileNotFoundException(this.filename) : assert(filename != null);

  @override
  String toString() {
    return 'FileNotFoundException{filename: $filename}';
  }
}
