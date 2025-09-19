import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/utils.dart';

/// Implementation of a picture (sequence of recorded image operations) or a bitmap (raw pixel data). Note that the image must be disposed after use.
class TilePicture {
  final ui.Picture? _picture;

  final ui.Image? _image;

  TilePicture._(this._picture, this._image);

  TilePicture.fromPicture(this._picture) : _image = null;

  // Instantiates a new TilePicture object and holds the given image. Note that the responsibility to dispose the image is transferred to this class hence the
  // class MUST be disposed after use.
  TilePicture.fromBitmap(this._image)
    : assert(_image != null, "Image must not be null"),
      assert(!_image!.debugDisposed, "Image is already disposed"),
      _picture = null;

  TilePicture clone() {
    return TilePicture._(_picture, _image?.clone());
  }

  ui.Picture? getPicture() {
    return _picture;
  }

  ui.Image? getImage() {
    if (_image != null) assert(!_image.debugDisposed, "Image is already disposed");
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
