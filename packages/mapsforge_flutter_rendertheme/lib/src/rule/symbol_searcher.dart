import 'package:mapsforge_flutter_core/model.dart';

abstract class SymbolSearcher {
  MapRectangle? searchForSymbolBoundary(String symbolId);
}
