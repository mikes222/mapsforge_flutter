import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

class ImageBuilder {
  const ImageBuilder();

  /// Make sure this method runs in a real loop, not a fake-loop while testing. Use e.g.
  ///
  ///     await tester.runAsync(() async {...});
  Future<SymbolImage> createPngSymbol(Uint8List bytes, int width, int height) async {
    if (width != 0 && height != 0) {
      var codec = await ui.instantiateImageCodec(bytes, targetHeight: height, targetWidth: width);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      SymbolImage result = SymbolImage(img);
      return result;
    } else {
      var codec = await ui.instantiateImageCodec(bytes);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      SymbolImage result = SymbolImage(img);
      return result;
    }
  }

  /// Make sure this method runs in a real loop, not a fake-loop while testing. Use e.g.
  ///
  ///     await tester.runAsync(() async {...});
  Future<SymbolImage> createSvgSymbol(Uint8List bytes, int width, int height) async {
    PictureInfo pictureInfo = await vg.loadPicture(SvgBytesLoader(bytes), null);
    final ui.Picture picture = pictureInfo.picture;
    ui.Image image = await picture.toImage(pictureInfo.size.width.round(), pictureInfo.size.height.round());
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    pictureInfo.picture.dispose();
    if (width != 0 && height != 0) {
      var codec = await ui.instantiateImageCodec(byteData!.buffer.asUint8List(), targetHeight: height, targetWidth: width);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      SymbolImage result = SymbolImage(img);
      return result;
    } else {
      var codec = await ui.instantiateImageCodec(byteData!.buffer.asUint8List());
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      SymbolImage result = SymbolImage(img);
      return result;
    }
  }
}
