import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';

class FlutterTilePicture extends TilePicture {
  final Picture picture;

  FlutterTilePicture(this.picture);

  @override
  void dispose() {
    picture.dispose();
  }
}
