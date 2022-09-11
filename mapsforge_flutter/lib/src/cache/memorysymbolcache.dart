import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/cache/imagebuilder.dart';
import 'package:mapsforge_flutter/src/cache/imageloader.dart';
import 'package:mapsforge_flutter/src/exceptions/symbolnotfoundexception.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

/// The two caches are now the same
@Deprecated(
    "Use FileSymbolCache instead and overwrite the imageloader and/or imagebuilder if needed")
class MemorySymbolCache extends FileSymbolCache {}
