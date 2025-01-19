class FileNotFoundException implements Exception {
  final String filename;

  FileNotFoundException(this.filename);

  @override
  String toString() {
    return 'FileNotFoundException{filename: $filename}';
  }
}
