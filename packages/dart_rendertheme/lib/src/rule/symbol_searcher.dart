import 'package:dart_common/model.dart';

abstract class SymbolSearcher {
  MapRectangle? searchForSymbolBoundary(String symbolId);
}
