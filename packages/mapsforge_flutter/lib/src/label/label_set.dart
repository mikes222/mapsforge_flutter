import 'package:dart_rendertheme/model.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter_core/model.dart';

class LabelSet {
  final Mappoint center;

  final MapPosition mapPosition;

  List<RenderInfoCollection> renderInfos;

  LabelSet({required this.center, required this.mapPosition, required this.renderInfos});

  Mappoint getCenter() => center;
}
