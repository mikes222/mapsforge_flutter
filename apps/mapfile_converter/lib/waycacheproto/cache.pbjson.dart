//
//  Generated code. Do not modify.
//  source: lib/pbfreader/waycacheproto/cache.pbfproto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use cacheWayDescriptor instead')
const CacheWay$json = {
  '1': 'CacheWay',
  '2': [
    {
      '1': 'lat',
      '3': 9,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'lat',
    },
    {
      '1': 'lon',
      '3': 10,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'lon',
    },
  ],
};

/// Descriptor for `CacheWay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheWayDescriptor = $convert.base64Decode('CghDYWNoZVdheRIUCgNsYXQYCSADKBJCAhABUgNsYXQSFAoDbG9uGAogAygSQgIQAVIDbG9u');

@$core.Deprecated('Use cacheLabelDescriptor instead')
const CacheLabel$json = {
  '1': 'CacheLabel',
  '2': [
    {'1': 'lat', '3': 8, '4': 2, '5': 18, '10': 'lat'},
    {'1': 'lon', '3': 9, '4': 2, '5': 18, '10': 'lon'},
  ],
};

/// Descriptor for `CacheLabel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheLabelDescriptor = $convert.base64Decode('CgpDYWNoZUxhYmVsEhAKA2xhdBgIIAIoElIDbGF0EhAKA2xvbhgJIAIoElIDbG9u');

@$core.Deprecated('Use cacheWayholderDescriptor instead')
const CacheWayholder$json = {
  '1': 'CacheWayholder',
  '2': [
    {'1': 'tagkeys', '3': 2, '4': 3, '5': 9, '10': 'tagkeys'},
    {'1': 'tagvals', '3': 3, '4': 3, '5': 9, '10': 'tagvals'},
    {'1': 'innerways', '3': 4, '4': 3, '5': 11, '6': '.CacheWay', '10': 'innerways'},
    {'1': 'closedways', '3': 5, '4': 3, '5': 11, '6': '.CacheWay', '10': 'closedways'},
    {'1': 'openways', '3': 6, '4': 3, '5': 11, '6': '.CacheWay', '10': 'openways'},
    {'1': 'label', '3': 11, '4': 1, '5': 11, '6': '.CacheLabel', '10': 'label'},
    {'1': 'layer', '3': 13, '4': 2, '5': 5, '10': 'layer'},
    {'1': 'tileBitmask', '3': 14, '4': 2, '5': 5, '10': 'tileBitmask'},
    {'1': 'mergedWithOtherWay', '3': 15, '4': 2, '5': 8, '10': 'mergedWithOtherWay'},
  ],
};

/// Descriptor for `CacheWayholder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheWayholderDescriptor = $convert.base64Decode('Cg5DYWNoZVdheWhvbGRlchIYCgd0YWdrZXlzGAIgAygJUgd0YWdrZXlzEhgKB3RhZ3ZhbHMYAy'
    'ADKAlSB3RhZ3ZhbHMSJwoJaW5uZXJ3YXlzGAQgAygLMgkuQ2FjaGVXYXlSCWlubmVyd2F5cxIp'
    'CgpjbG9zZWR3YXlzGAUgAygLMgkuQ2FjaGVXYXlSCmNsb3NlZHdheXMSJQoIb3BlbndheXMYBi'
    'ADKAsyCS5DYWNoZVdheVIIb3BlbndheXMSIQoFbGFiZWwYCyABKAsyCy5DYWNoZUxhYmVsUgVs'
    'YWJlbBIUCgVsYXllchgNIAIoBVIFbGF5ZXISIAoLdGlsZUJpdG1hc2sYDiACKAVSC3RpbGVCaX'
    'RtYXNrEi4KEm1lcmdlZFdpdGhPdGhlcldheRgPIAIoCFISbWVyZ2VkV2l0aE90aGVyV2F5');
