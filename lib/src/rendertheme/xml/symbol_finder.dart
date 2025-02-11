import '../shape/shape_symbol.dart';

class ZoomlevelSymbolFinder {
  final ZoomlevelSymbolFinder? _parentZoomlevelSymbolFinder;

  Map<int, SymbolFinder> _symbolFinders = {};

  ZoomlevelSymbolFinder(this._parentZoomlevelSymbolFinder);

  SymbolFinder find(int zoomLevel) {
    if (_symbolFinders.containsKey(zoomLevel)) {
      return _symbolFinders[zoomLevel]!;
    }
    _symbolFinders[zoomLevel] =
        SymbolFinder(_parentZoomlevelSymbolFinder?.find(zoomLevel));
    return _symbolFinders[zoomLevel]!;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Finds a symbol denoted by an id. Some instructions (mostly captions) refers to a symbol. This couples symbol is denoted with an id. See for example "bus-stop".
/// The referred symbol may exist at the same level or above (towards rooot) in the xml file.
class SymbolFinder {
  final SymbolFinder? parentSymbolFinder;

  // map of symbolIds contains a map of zoomLevels
  final Map<String, SymbolHolder> _symbols = {};

  SymbolFinder(this.parentSymbolFinder);

  void add(String symbolId, ShapeSymbol shapeSymbol) {
    if (!_symbols.containsKey(symbolId)) {
      _symbols[symbolId] = SymbolHolder();
    }
    _symbols[symbolId]!.shapeSymbol = shapeSymbol;
  }

  SymbolHolder? search(String symbolId) {
    if (_symbols.containsKey(symbolId)) {
      return _symbols[symbolId];
    }
    return parentSymbolFinder?.search(symbolId);
  }

  SymbolHolder findSymbolHolder(String symbolId) {
    SymbolHolder? result = search(symbolId);
    if (result != null) return result;

    result = SymbolHolder();
    _symbols[symbolId] = result;
    parentSymbolFinder?.set(symbolId, result);
    return result;
  }

  void set(String symbolId, SymbolHolder symbolHolder) {
    _symbols[symbolId] = symbolHolder;
    parentSymbolFinder?.set(symbolId, symbolHolder);
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
