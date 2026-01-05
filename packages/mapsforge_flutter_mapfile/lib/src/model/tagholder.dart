import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class Tagholder {
  /// This field has two meanings. As part of the [TagholderModel] it is the sorted index of the tag. Mapfiles requires that the most used tag has the lowest index.
  /// As any other part it is the index of the corresponding Tagholder in the [TagholderModel].
  int? index;

  final String key;

  final String value;

  Tagholder(this.key, this.value);

  @override
  String toString() {
    return 'Tagholder{index: $index, key: $key, value: $value}';
  }
}
