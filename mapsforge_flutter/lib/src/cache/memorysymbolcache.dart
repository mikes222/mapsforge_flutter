
import 'package:mapsforge_flutter/core.dart';

/// The two caches are now the same
@Deprecated(
    "Use FileSymbolCache instead and overwrite the imageloader and/or imagebuilder if needed")
class MemorySymbolCache extends FileSymbolCache {}
