// The required tiles to fill the screen.
class TileDimension {
  final int minLeft;

  final int minRight;

  final int minTop;

  final int minBottom;

  final int left;

  final int right;

  final int top;

  final int bottom;

  const TileDimension({
    required this.minLeft,
    required this.minRight,
    required this.minTop,
    required this.minBottom,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  }) : assert(minLeft <= minRight),
       assert(minTop <= minBottom),
       assert(minLeft >= 0),
       assert(minBottom >= 0),
       assert(left <= right),
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

  // Returns true of the minimum tiles of other are contained in this.
  bool contains(TileDimension other) {
    return left <= other.minLeft && right >= other.minRight && top <= other.minTop && bottom >= other.minBottom;
  }
}
