mixin FillSrcMixin {
  /// For texts the fillColor is the inner color, whereas the strokeColor is the surrounding "frame" of the text
  int fillColor = transparent();

  void setFillColorFromNumber(int color) {
    fillColor = color;
  }

  void fillSrcMixinClone(FillSrcMixin base) {
    fillColor = base.fillColor;
  }

  void fillSrcMixinScale(FillSrcMixin base, int zoomlevel) {
    fillSrcMixinClone(base);
  }

  bool isFillTransparent() {
    return fillColor == transparent();
  }

  static int transparent() => 0x00000000;
}
