import 'package:dart_rendertheme/renderinstruction.dart';

abstract class SymbolSearcher {
  RenderinstructionSymbol? searchForSymbol(String symbolId);
}
