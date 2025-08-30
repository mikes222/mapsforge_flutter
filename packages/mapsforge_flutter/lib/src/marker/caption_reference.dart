import 'package:mapsforge_flutter_core/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';

abstract class CaptionReference extends SymbolSearcher {
  ILatLong getReference();
}
