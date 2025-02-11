import '../shape/shape_symbol.dart';

/// Finds a symbol denoted by an id. Some instructions (mostly captions) refers to a symbol. This couples symbol is denoted with an id. See for example "bus-stop".
/// The referred symbol may exist at the same level or above (towards rooot) in the xml file.
class SymbolFinder {
  final SymbolFinder? parentSymbolFinder;

  // map of symbolIds contains a map of zoomLevels
  final Map<String, Map<int, SymbolHolder>> _symbols = {};

  SymbolFinder(this.parentSymbolFinder);

  void add(String symbolId, int zoomLevel, ShapeSymbol shapeSymbol) {
    if (!_symbols.containsKey(symbolId)) {
      _symbols[symbolId] = {};
    }
    Map<int, SymbolHolder> holders = _symbols[symbolId]!;
    if (!holders.containsKey(zoomLevel)) {
      holders[zoomLevel] = SymbolHolder();
    }
    holders[zoomLevel]!.shapeSymbol = shapeSymbol;
  }

  SymbolHolder? search(String symbolId, int zoomLevel) {
    if (_symbols.containsKey(symbolId)) {
      Map<int, SymbolHolder> holders = _symbols[symbolId]!;
      if (holders.containsKey(zoomLevel)) {
        return holders[zoomLevel];
      }
    }
    return parentSymbolFinder?.search(symbolId, zoomLevel);
  }

  SymbolHolder findSymbolHolder(String symbolId, int zoomLevel) {
    SymbolHolder? result = search(symbolId, zoomLevel);
    if (result != null) return result;

    if (!_symbols.containsKey(symbolId)) {
      _symbols[symbolId] = {};
    }
    Map<int, SymbolHolder> holders = _symbols[symbolId]!;
    if (!holders.containsKey(zoomLevel)) {
      holders[zoomLevel] = SymbolHolder();
      // hope that the shapeSymbol will be added later to this holder
    }
    return holders[zoomLevel]!;
  }
}

/////////////////////////////////////////////////////////////////////////////

class SymbolHolder {
  ShapeSymbol? shapeSymbol;

  @override
  String toString() {
    return 'SymbolHolder{shapeSymbol: $shapeSymbol}';
  }
}
