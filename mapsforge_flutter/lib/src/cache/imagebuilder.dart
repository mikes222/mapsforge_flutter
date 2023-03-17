import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterresourcebitmap.dart';

class ImageBuilder {
  const ImageBuilder();

  Future<FlutterResourceBitmap> createPngSymbol(
      ByteData content, String src, int width, int height) async {
    Uint8List bytes = content.buffer.asUint8List();
    if (width != 0 && height != 0) {
      var codec = await ui.instantiateImageCodec(bytes,
          targetHeight: height, targetWidth: width);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      FlutterResourceBitmap result = FlutterResourceBitmap(img, src);
      return result;
    } else {
      var codec = await ui.instantiateImageCodec(bytes);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      FlutterResourceBitmap result = FlutterResourceBitmap(img, src);
      return result;
    }
  }

  Future<FlutterResourceBitmap> createSvgSymbol(
      ByteData content, String src, int width, int height) async {
    PictureInfo pictureInfo = await vg.loadPicture(
        SvgBytesLoader(content.buffer.asUint8List()), null);
    final ui.Picture picture = pictureInfo.picture;
    ui.Image image = await picture.toImage(width, height);
    FlutterResourceBitmap result = FlutterResourceBitmap(image, src);
    pictureInfo.picture.dispose();
    return result;
  }
}
