import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

abstract class CaptionReference extends SymbolSearcher {
  ILatLong getReference();
}
