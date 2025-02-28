//
//  Generated code. Do not modify.
//  source: lib/proto/fileformat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use blobDescriptor instead')
const Blob$json = {
  '1': 'Blob',
  '2': [
    {'1': 'raw', '3': 1, '4': 1, '5': 12, '10': 'raw'},
    {'1': 'raw_size', '3': 2, '4': 1, '5': 5, '10': 'rawSize'},
    {'1': 'zlib_data', '3': 3, '4': 1, '5': 12, '10': 'zlibData'},
    {'1': 'lzma_data', '3': 4, '4': 1, '5': 12, '10': 'lzmaData'},
    {
      '1': 'OBSOLETE_bzip2_data',
      '3': 5,
      '4': 1,
      '5': 12,
      '8': {'3': true},
      '10': 'OBSOLETEBzip2Data',
    },
  ],
};

/// Descriptor for `Blob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blobDescriptor = $convert.base64Decode(
    'CgRCbG9iEhAKA3JhdxgBIAEoDFIDcmF3EhkKCHJhd19zaXplGAIgASgFUgdyYXdTaXplEhsKCX'
    'psaWJfZGF0YRgDIAEoDFIIemxpYkRhdGESGwoJbHptYV9kYXRhGAQgASgMUghsem1hRGF0YRIy'
    'ChNPQlNPTEVURV9iemlwMl9kYXRhGAUgASgMQgIYAVIRT0JTT0xFVEVCemlwMkRhdGE=');

@$core.Deprecated('Use blobHeaderDescriptor instead')
const BlobHeader$json = {
  '1': 'BlobHeader',
  '2': [
    {'1': 'type', '3': 1, '4': 2, '5': 9, '10': 'type'},
    {'1': 'indexdata', '3': 2, '4': 1, '5': 12, '10': 'indexdata'},
    {'1': 'datasize', '3': 3, '4': 2, '5': 5, '10': 'datasize'},
  ],
};

/// Descriptor for `BlobHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blobHeaderDescriptor = $convert.base64Decode(
    'CgpCbG9iSGVhZGVyEhIKBHR5cGUYASACKAlSBHR5cGUSHAoJaW5kZXhkYXRhGAIgASgMUglpbm'
    'RleGRhdGESGgoIZGF0YXNpemUYAyACKAVSCGRhdGFzaXpl');
