import 'dart:typed_data';

import 'package:mapsforge_flutter_core/projection.dart';

abstract class TileColorRenderer {
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int elevation);
}
