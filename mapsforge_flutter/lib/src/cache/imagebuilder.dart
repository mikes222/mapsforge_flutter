import 'dart:typed_data';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterresourcebitmap.dart';
import 'dart:ui' as ui;

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
    DrawableRoot svgRoot =
        await svg.fromSvgBytes(content.buffer.asUint8List(), src);

// If you only want the final Picture output, just use
    final ui.Picture picture =
        svgRoot.toPicture(size: ui.Size(width.toDouble(), height.toDouble()));
    ui.Image image = await picture.toImage(width, height);
    //print("image: " + image.toString());
    FlutterResourceBitmap result = FlutterResourceBitmap(image, src);
    return result;

    //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

    //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
  }
}
