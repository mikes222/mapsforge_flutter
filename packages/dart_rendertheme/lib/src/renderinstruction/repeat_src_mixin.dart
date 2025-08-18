mixin RepeatSrcMixin {
  bool repeat = true;

  late double repeatGap;

  late double repeatStart;

  bool rotate = true;

  void setRepeatGap(double repeatGap) {
    this.repeatGap = repeatGap;
  }
}
