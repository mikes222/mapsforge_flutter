mixin FillColorSrcMixin {
  /// For texts the fillColor is the inner color, whereas the strokeColor is the surrounding "frame" of the text
  int fillColor = transparent();

  void setFillColorFromNumber(int color) {
    fillColor = color;
  }

  void fillColorSrcMixinClone(FillColorSrcMixin base) {
    fillColor = base.fillColor;
  }

  void fillColorSrcMixinScale(FillColorSrcMixin base, int zoomlevel) {
    fillColorSrcMixinClone(base);
  }

  bool isFillTransparent() {
    return fillColor == transparent();
  }

  static int transparent() => 0x00000000;
}
