import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/model.dart';
import 'package:flutter/material.dart';

/// A wrapper for a `ui.Image` that represents a bitmap symbol.
///
/// This class manages the underlying `ui.Image` and provides methods for
/// accessing its properties, cloning it, and creating shaders from it. It is
/// crucial to call [dispose] when the image is no longer needed to release
/// its resources.
class SymbolImage {
  final ui.Image _image;

  SymbolImage(this._image);

  /// Returns the height of the symbol image.
  int getHeight() {
    return _image.height;
  }

  /// Returns the width of the symbol image.
  int getWidth() {
    return _image.width;
  }

  /// Disposes the underlying `ui.Image` to release its resources.
  void dispose() {
    _image.dispose();
  }

  /// Creates a clone of this [SymbolImage].
  ///
  /// The underlying `ui.Image` is also cloned, and it will only be disposed
  /// when all clones have been disposed.
  SymbolImage clone() {
    return SymbolImage(_image.clone());
  }

  /// Creates an `ImageShader` from the symbol image.
  ///
  /// This is used to create pattern fills for areas and polylines.
  ui.ImageShader getShader() {
    // final double devicePixelRatio = ui.window.devicePixelRatio;
    // final Float64List deviceTransform = new Float64List(16)
    //   ..[0] = devicePixelRatio
    //   ..[5] = devicePixelRatio
    //   ..[10] = 1.0
    //   ..[15] = 2.0;
    return ui.ImageShader(_image, ui.TileMode.repeated, ui.TileMode.repeated, Matrix4.identity().storage);
  }

  /// Returns the boundary of the symbol, centered at (0,0).
  MapRectangle getBoundary() {
    return MapRectangle(-_image.width / 2, -_image.height / 2, _image.width / 2, _image.height / 2);
  }

  /// Exposes the underlying `ui.Image` for direct use.
  ///
  /// Use with caution, as the caller is responsible for not disposing the
  /// image while it is still in use by this [SymbolImage] or its clones.
  ui.Image expose() => _image;
}
