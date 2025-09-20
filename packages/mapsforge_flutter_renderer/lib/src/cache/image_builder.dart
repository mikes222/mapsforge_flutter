import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

/// A utility class for creating `SymbolImage` objects from raw byte data.
///
/// This class handles the decoding and resizing of PNG and SVG images.
class ImageBuilder {
  const ImageBuilder();

  /// Creates a `SymbolImage` from PNG data.
  ///
  /// If [width] and [height] are specified, the image is resized to the given
  /// dimensions.
  ///
  /// When using this in tests, ensure it runs in a real async zone, for example
  /// by wrapping it with `tester.runAsync()`.
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

  /// Creates a `SymbolImage` from SVG data.
  ///
  /// The SVG is first rendered to a `ui.Picture`, then converted to a PNG, and
  /// finally decoded and resized as specified.
  ///
  /// When using this in tests, ensure it runs in a real async zone, for example
  /// by wrapping it with `tester.runAsync()`.
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
