class Tagholder {
  // how often is the tag used. We will use this for sorting tags
  int _count = 0;

  // the index of the tag after sorting
  int? index;

  String key;

  String value;

  Tagholder(this.key, this.value);

  @override
  String toString() {
    return 'Tagholder{count: $_count, index: $index, key: $key, value: $value}';
  }

  void incrementCount() {
    _count++;
  }

  int get count => _count;
}
