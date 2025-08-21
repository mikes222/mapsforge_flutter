import 'package:datastore_renderer/src/cache/filesymbolcache.dart';
import 'package:datastore_renderer/src/cache/symbolcache.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';

class SymbolCacheMgr {
  static SymbolCacheMgr? _instance;

  late SymbolCache symbolCache;

  SymbolCacheMgr._() {
    symbolCache = FileSymbolCache();
  }

  factory SymbolCacheMgr() {
    if (_instance != null) return _instance!;
    _instance = SymbolCacheMgr._();
    return _instance!;
  }

  ///
  /// loads and returns the desired symbol, optionally rescales it to the given width and height
  ///
  Future<SymbolImage?> getOrCreateSymbol(String src, int width, int height) async {
    return symbolCache.getOrCreateSymbol(src, width, height);
  }
}
