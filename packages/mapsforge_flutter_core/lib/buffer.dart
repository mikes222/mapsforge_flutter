/// Buffer utilities for reading and writing binary data.
///
/// This library provides classes for:
/// - Reading binary data from various sources (files, memory, web)
/// - Writing binary data with proper serialization
/// - Deserializing complex data structures from binary formats
/// - Cross-platform buffer handling for Mapsforge data
library;

export 'src/buffer/deserializer.dart';
export 'src/buffer/readbuffer.dart';
export 'src/buffer/readbuffer_factory.dart';
export 'src/buffer/readbuffer_memory.dart';
export 'src/buffer/readbuffer_source.dart';
export 'src/buffer/writebuffer_platform.dart';
