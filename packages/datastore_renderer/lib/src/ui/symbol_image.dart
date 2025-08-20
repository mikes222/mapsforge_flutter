import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A wrapper for ui images. Do not forget to dispose() this class after use
class SymbolImage {
  final ui.Image _image;

  SymbolImage(this._image);

  int getHeight() {
    return _image.height;
  }

  int getWidth() {
    return _image.width;
  }

  void dispose() {
    _image.dispose();
  }

  /// Clones this class. The underlying image will be disposed only when all clones are disposed.
  SymbolImage clone() {
    return SymbolImage(_image.clone());
  }

  ui.ImageShader getShader() {
    // final double devicePixelRatio = ui.window.devicePixelRatio;
    // final Float64List deviceTransform = new Float64List(16)
    //   ..[0] = devicePixelRatio
    //   ..[5] = devicePixelRatio
    //   ..[10] = 1.0
    //   ..[15] = 2.0;
    return ui.ImageShader(_image, ui.TileMode.repeated, ui.TileMode.repeated, Matrix4.identity().storage);
  }

  ui.Image expose() => _image;
}
