import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file_web_js.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// Factory for creating a `ReadbufferSource` on the JavaScript web platform.
ReadbufferSource createReadbufferSource(String pathOrUrl, [dynamic file]) {
  if (file != null) {
    return ReadbufferFileWebJs.fromFile(file);
  } else {
    return ReadbufferFileWebJs.fromUrl(pathOrUrl);
  }
}
