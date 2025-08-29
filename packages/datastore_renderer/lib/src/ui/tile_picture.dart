import 'dart:ui' as ui;

import 'package:dart_common/utils.dart';

/// Implementation of a picture (sequence of recorded image operations) or a bitmap (raw pixel data). Note that the image must be disposed after use.
class TilePicture {
  final ui.Picture? _picture;

  final ui.Image? _image;

  TilePicture.fromPicture(this._picture) : _image = null;

  // Instantiates a new TilePicture object and holds the given image. Note that the responsibility to dispose the image is transferred to this class hence the
  // class MUST be disposed after use.
  TilePicture.fromBitmap(this._image) : _picture = null;

  ui.Picture? getPicture() {
    return _picture;
  }

  ui.Image? getImage() {
    return _image;
  }

  Future<ui.Image> convertPictureToImage() async {
    if (_image != null) return _image;
    return await _picture!.toImage(MapsforgeSettingsMgr().tileSize.round(), MapsforgeSettingsMgr().tileSize.round());
  }

  void dispose() {
    _picture?.dispose();
    _image?.dispose();
  }
}
