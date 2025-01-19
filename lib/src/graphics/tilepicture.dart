import 'dart:ui' as ui;

abstract class TilePicture {
  void dispose();

  ui.Picture? getPicture();

  //ui.Image? getImage();

  ui.Image? getClonedImage();

  Future<ui.Image> convertToImage();
}
