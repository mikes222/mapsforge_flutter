import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/utils.dart';

/// A container for either a `ui.Picture` (a recorded sequence of drawing
/// commands) or a `ui.Image` (raw pixel data).
///
/// This class is used to represent a rendered map tile. It can be created from
/// either a picture or a bitmap, and it handles the disposal of the underlying
/// graphics resources. It is crucial to call [dispose] when the tile is no
/// longer needed.
class TilePicture {
  final ui.Picture? _picture;

  late final bool _pictureCloned;

  ui.Image? _image;

  TilePicture._(this._picture, this._image) {
    _pictureCloned = _picture != null;
  }

  /// Creates a [TilePicture] from a `ui.Picture`.
  TilePicture.fromPicture(this._picture) : _image = null, _pictureCloned = false;

  /// Creates a [TilePicture] from a `ui.Image`.
  ///
  /// The responsibility to dispose the image is transferred to this class.
  TilePicture.fromBitmap(this._image)
    : assert(_image != null, "Image must not be null"),
      assert(!_image!.debugDisposed, "Image is already disposed"),
      _picture = null,
      _pictureCloned = false;

  /// Creates a clone of this [TilePicture].
  ///
  /// The underlying `ui.Image` is also cloned if it exists.
  TilePicture clone() {
    return TilePicture._(_picture, _image?.clone());
  }

  /// Returns the underlying `ui.Picture`, if it exists.
  ui.Picture? getPicture() {
    return _picture;
  }

  /// Returns the underlying `ui.Image`, if it exists.
  ui.Image? getImage() {
    if (_image != null) assert(!_image!.debugDisposed, "Image is already disposed");
    return _image?.clone();
  }

  /// Converts the underlying `ui.Picture` to a `ui.Image`.
  ///
  /// If this [TilePicture] already contains an image, that image is returned directly.
  ui.Image convertPictureToImage() {
    if (_image != null) return _image!;
    _image = _picture!.toImageSync(MapsforgeSettingsMgr().tileSize.round(), MapsforgeSettingsMgr().tileSize.round());
    return _image!.clone();
  }

  /// Disposes the underlying `ui.Picture` and/or `ui.Image` to release their resources.
  void dispose() {
    if (!_pictureCloned) _picture?.dispose();
    _image?.dispose();
  }
}
