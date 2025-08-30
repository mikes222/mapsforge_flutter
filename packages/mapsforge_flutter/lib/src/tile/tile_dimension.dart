class TileDimension {
  final int left;

  final int right;

  final int top;

  final int bottom;

  const TileDimension({required this.left, required this.right, required this.top, required this.bottom})
    : assert(left <= right),
      assert(top <= bottom),
      assert(left >= 0),
      assert(bottom >= 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileDimension && runtimeType == other.runtimeType && left == other.left && right == other.right && top == other.top && bottom == other.bottom;

  @override
  int get hashCode => left.hashCode ^ right.hashCode ^ top.hashCode ^ bottom.hashCode;

  @override
  String toString() {
    return 'TileDimension{left: $left, right: $right, top: $top, bottom: $bottom}';
  }

  bool contains(TileDimension other) {
    return left <= other.left && right >= other.right && top <= other.top && bottom >= other.bottom;
  }
}
