import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:mapsforge_view/mapsforge.dart';

class LabelSet {
  final Mappoint center;

  final MapPosition mapPosition;

  List<RenderInfoCollection> renderInfos;

  LabelSet({required this.center, required this.mapPosition, required this.renderInfos});

  Mappoint getCenter() => center;
}
