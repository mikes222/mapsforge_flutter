import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

class FlutterTilePicture extends TilePicture {
  final ui.Picture? _picture;

  final ui.Image? _bitmap;

  FlutterTilePicture.fromPicture(this._picture) : _bitmap = null;

  FlutterTilePicture.fromBitmap(this._bitmap) : _picture = null;

  @override
  ui.Picture? getPicture() {
    return _picture;
  }

  // @override
  // ui.Image? getImage() {
  //   return _bitmap;
  // }

  @override
  ui.Image? getClonedImage() {
    return _bitmap?.clone();
  }

  @override
  Future<ui.Image> convertToImage() async {
    if (_bitmap != null) return _bitmap!;
    return await _picture!.toImage(MapsforgeConstants().tileSize.round(),
        MapsforgeConstants().tileSize.round());
  }

  @override
  void dispose() {
    _picture?.dispose();
    _bitmap?.dispose();
  }
}
