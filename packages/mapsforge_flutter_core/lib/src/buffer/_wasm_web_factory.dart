import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file_web_wasm.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// Factory for creating a `ReadbufferSource` on the WASM web platform.
ReadbufferSource createReadbufferSource(String pathOrUrl, [dynamic file]) {
  // The `file` parameter is ignored on WASM as it's not supported.
  return ReadbufferFileWebWasm.fromUrl(pathOrUrl);
}
