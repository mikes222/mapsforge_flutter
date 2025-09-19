import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file_io.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// Factory for creating a `ReadbufferSource` on IO platforms.
ReadbufferSource createReadbufferSource(String pathOrUrl, [dynamic file]) {
  return ReadbufferFile(pathOrUrl);
}
