//
//  Generated code. Do not modify.
//  source: lib/proto/osmformat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use headerBlockDescriptor instead')
const HeaderBlock$json = {
  '1': 'HeaderBlock',
  '2': [
    {
      '1': 'bbox',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.OSMPBF.HeaderBBox',
      '10': 'bbox'
    },
    {
      '1': 'required_features',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'requiredFeatures'
    },
    {
      '1': 'optional_features',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'optionalFeatures'
    },
    {'1': 'writingprogram', '3': 16, '4': 1, '5': 9, '10': 'writingprogram'},
    {'1': 'source', '3': 17, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'osmosis_replication_timestamp',
      '3': 32,
      '4': 1,
      '5': 3,
      '10': 'osmosisReplicationTimestamp'
    },
    {
      '1': 'osmosis_replication_sequence_number',
      '3': 33,
      '4': 1,
      '5': 3,
      '10': 'osmosisReplicationSequenceNumber'
    },
    {
      '1': 'osmosis_replication_base_url',
      '3': 34,
      '4': 1,
      '5': 9,
      '10': 'osmosisReplicationBaseUrl'
    },
  ],
};

/// Descriptor for `HeaderBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headerBlockDescriptor = $convert.base64Decode(
    'CgtIZWFkZXJCbG9jaxImCgRiYm94GAEgASgLMhIuT1NNUEJGLkhlYWRlckJCb3hSBGJib3gSKw'
    'oRcmVxdWlyZWRfZmVhdHVyZXMYBCADKAlSEHJlcXVpcmVkRmVhdHVyZXMSKwoRb3B0aW9uYWxf'
    'ZmVhdHVyZXMYBSADKAlSEG9wdGlvbmFsRmVhdHVyZXMSJgoOd3JpdGluZ3Byb2dyYW0YECABKA'
    'lSDndyaXRpbmdwcm9ncmFtEhYKBnNvdXJjZRgRIAEoCVIGc291cmNlEkIKHW9zbW9zaXNfcmVw'
    'bGljYXRpb25fdGltZXN0YW1wGCAgASgDUhtvc21vc2lzUmVwbGljYXRpb25UaW1lc3RhbXASTQ'
    'ojb3Ntb3Npc19yZXBsaWNhdGlvbl9zZXF1ZW5jZV9udW1iZXIYISABKANSIG9zbW9zaXNSZXBs'
    'aWNhdGlvblNlcXVlbmNlTnVtYmVyEj8KHG9zbW9zaXNfcmVwbGljYXRpb25fYmFzZV91cmwYIi'
    'ABKAlSGW9zbW9zaXNSZXBsaWNhdGlvbkJhc2VVcmw=');

@$core.Deprecated('Use headerBBoxDescriptor instead')
const HeaderBBox$json = {
  '1': 'HeaderBBox',
  '2': [
    {'1': 'left', '3': 1, '4': 2, '5': 18, '10': 'left'},
    {'1': 'right', '3': 2, '4': 2, '5': 18, '10': 'right'},
    {'1': 'top', '3': 3, '4': 2, '5': 18, '10': 'top'},
    {'1': 'bottom', '3': 4, '4': 2, '5': 18, '10': 'bottom'},
  ],
};

/// Descriptor for `HeaderBBox`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headerBBoxDescriptor = $convert.base64Decode(
    'CgpIZWFkZXJCQm94EhIKBGxlZnQYASACKBJSBGxlZnQSFAoFcmlnaHQYAiACKBJSBXJpZ2h0Eh'
    'AKA3RvcBgDIAIoElIDdG9wEhYKBmJvdHRvbRgEIAIoElIGYm90dG9t');

@$core.Deprecated('Use primitiveBlockDescriptor instead')
const PrimitiveBlock$json = {
  '1': 'PrimitiveBlock',
  '2': [
    {
      '1': 'stringtable',
      '3': 1,
      '4': 2,
      '5': 11,
      '6': '.OSMPBF.StringTable',
      '10': 'stringtable'
    },
    {
      '1': 'primitivegroup',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.OSMPBF.PrimitiveGroup',
      '10': 'primitivegroup'
    },
    {
      '1': 'granularity',
      '3': 17,
      '4': 1,
      '5': 5,
      '7': '100',
      '10': 'granularity'
    },
    {'1': 'lat_offset', '3': 19, '4': 1, '5': 3, '7': '0', '10': 'latOffset'},
    {'1': 'lon_offset', '3': 20, '4': 1, '5': 3, '7': '0', '10': 'lonOffset'},
    {
      '1': 'date_granularity',
      '3': 18,
      '4': 1,
      '5': 5,
      '7': '1000',
      '10': 'dateGranularity'
    },
  ],
};

/// Descriptor for `PrimitiveBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List primitiveBlockDescriptor = $convert.base64Decode(
    'Cg5QcmltaXRpdmVCbG9jaxI1CgtzdHJpbmd0YWJsZRgBIAIoCzITLk9TTVBCRi5TdHJpbmdUYW'
    'JsZVILc3RyaW5ndGFibGUSPgoOcHJpbWl0aXZlZ3JvdXAYAiADKAsyFi5PU01QQkYuUHJpbWl0'
    'aXZlR3JvdXBSDnByaW1pdGl2ZWdyb3VwEiUKC2dyYW51bGFyaXR5GBEgASgFOgMxMDBSC2dyYW'
    '51bGFyaXR5EiAKCmxhdF9vZmZzZXQYEyABKAM6ATBSCWxhdE9mZnNldBIgCgpsb25fb2Zmc2V0'
    'GBQgASgDOgEwUglsb25PZmZzZXQSLwoQZGF0ZV9ncmFudWxhcml0eRgSIAEoBToEMTAwMFIPZG'
    'F0ZUdyYW51bGFyaXR5');

@$core.Deprecated('Use primitiveGroupDescriptor instead')
const PrimitiveGroup$json = {
  '1': 'PrimitiveGroup',
  '2': [
    {'1': 'nodes', '3': 1, '4': 3, '5': 11, '6': '.OSMPBF.Node', '10': 'nodes'},
    {
      '1': 'dense',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.OSMPBF.DenseNodes',
      '10': 'dense'
    },
    {'1': 'ways', '3': 3, '4': 3, '5': 11, '6': '.OSMPBF.Way', '10': 'ways'},
    {
      '1': 'relations',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.OSMPBF.Relation',
      '10': 'relations'
    },
    {
      '1': 'changesets',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.OSMPBF.ChangeSet',
      '10': 'changesets'
    },
  ],
};

/// Descriptor for `PrimitiveGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List primitiveGroupDescriptor = $convert.base64Decode(
    'Cg5QcmltaXRpdmVHcm91cBIiCgVub2RlcxgBIAMoCzIMLk9TTVBCRi5Ob2RlUgVub2RlcxIoCg'
    'VkZW5zZRgCIAEoCzISLk9TTVBCRi5EZW5zZU5vZGVzUgVkZW5zZRIfCgR3YXlzGAMgAygLMgsu'
    'T1NNUEJGLldheVIEd2F5cxIuCglyZWxhdGlvbnMYBCADKAsyEC5PU01QQkYuUmVsYXRpb25SCX'
    'JlbGF0aW9ucxIxCgpjaGFuZ2VzZXRzGAUgAygLMhEuT1NNUEJGLkNoYW5nZVNldFIKY2hhbmdl'
    'c2V0cw==');

@$core.Deprecated('Use stringTableDescriptor instead')
const StringTable$json = {
  '1': 'StringTable',
  '2': [
    {'1': 's', '3': 1, '4': 3, '5': 12, '10': 's'},
  ],
};

/// Descriptor for `StringTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringTableDescriptor =
    $convert.base64Decode('CgtTdHJpbmdUYWJsZRIMCgFzGAEgAygMUgFz');

@$core.Deprecated('Use infoDescriptor instead')
const Info$json = {
  '1': 'Info',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 5, '7': '-1', '10': 'version'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'changeset', '3': 3, '4': 1, '5': 3, '10': 'changeset'},
    {'1': 'uid', '3': 4, '4': 1, '5': 5, '10': 'uid'},
    {'1': 'user_sid', '3': 5, '4': 1, '5': 13, '10': 'userSid'},
    {'1': 'visible', '3': 6, '4': 1, '5': 8, '10': 'visible'},
  ],
};

/// Descriptor for `Info`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoDescriptor = $convert.base64Decode(
    'CgRJbmZvEhwKB3ZlcnNpb24YASABKAU6Ai0xUgd2ZXJzaW9uEhwKCXRpbWVzdGFtcBgCIAEoA1'
    'IJdGltZXN0YW1wEhwKCWNoYW5nZXNldBgDIAEoA1IJY2hhbmdlc2V0EhAKA3VpZBgEIAEoBVID'
    'dWlkEhkKCHVzZXJfc2lkGAUgASgNUgd1c2VyU2lkEhgKB3Zpc2libGUYBiABKAhSB3Zpc2libG'
    'U=');

@$core.Deprecated('Use denseInfoDescriptor instead')
const DenseInfo$json = {
  '1': 'DenseInfo',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 3,
      '5': 5,
      '8': {'2': true},
      '10': 'version',
    },
    {
      '1': 'timestamp',
      '3': 2,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'timestamp',
    },
    {
      '1': 'changeset',
      '3': 3,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'changeset',
    },
    {
      '1': 'uid',
      '3': 4,
      '4': 3,
      '5': 17,
      '8': {'2': true},
      '10': 'uid',
    },
    {
      '1': 'user_sid',
      '3': 5,
      '4': 3,
      '5': 17,
      '8': {'2': true},
      '10': 'userSid',
    },
    {
      '1': 'visible',
      '3': 6,
      '4': 3,
      '5': 8,
      '8': {'2': true},
      '10': 'visible',
    },
  ],
};

/// Descriptor for `DenseInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List denseInfoDescriptor = $convert.base64Decode(
    'CglEZW5zZUluZm8SHAoHdmVyc2lvbhgBIAMoBUICEAFSB3ZlcnNpb24SIAoJdGltZXN0YW1wGA'
    'IgAygSQgIQAVIJdGltZXN0YW1wEiAKCWNoYW5nZXNldBgDIAMoEkICEAFSCWNoYW5nZXNldBIU'
    'CgN1aWQYBCADKBFCAhABUgN1aWQSHQoIdXNlcl9zaWQYBSADKBFCAhABUgd1c2VyU2lkEhwKB3'
    'Zpc2libGUYBiADKAhCAhABUgd2aXNpYmxl');

@$core.Deprecated('Use changeSetDescriptor instead')
const ChangeSet$json = {
  '1': 'ChangeSet',
  '2': [
    {'1': 'id', '3': 1, '4': 2, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ChangeSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeSetDescriptor =
    $convert.base64Decode('CglDaGFuZ2VTZXQSDgoCaWQYASACKANSAmlk');

@$core.Deprecated('Use nodeDescriptor instead')
const Node$json = {
  '1': 'Node',
  '2': [
    {'1': 'id', '3': 1, '4': 2, '5': 18, '10': 'id'},
    {
      '1': 'keys',
      '3': 2,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'keys',
    },
    {
      '1': 'vals',
      '3': 3,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'vals',
    },
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.OSMPBF.Info', '10': 'info'},
    {'1': 'lat', '3': 8, '4': 2, '5': 18, '10': 'lat'},
    {'1': 'lon', '3': 9, '4': 2, '5': 18, '10': 'lon'},
  ],
};

/// Descriptor for `Node`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeDescriptor = $convert.base64Decode(
    'CgROb2RlEg4KAmlkGAEgAigSUgJpZBIWCgRrZXlzGAIgAygNQgIQAVIEa2V5cxIWCgR2YWxzGA'
    'MgAygNQgIQAVIEdmFscxIgCgRpbmZvGAQgASgLMgwuT1NNUEJGLkluZm9SBGluZm8SEAoDbGF0'
    'GAggAigSUgNsYXQSEAoDbG9uGAkgAigSUgNsb24=');

@$core.Deprecated('Use denseNodesDescriptor instead')
const DenseNodes$json = {
  '1': 'DenseNodes',
  '2': [
    {
      '1': 'id',
      '3': 1,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'id',
    },
    {
      '1': 'denseinfo',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.OSMPBF.DenseInfo',
      '10': 'denseinfo'
    },
    {
      '1': 'lat',
      '3': 8,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'lat',
    },
    {
      '1': 'lon',
      '3': 9,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'lon',
    },
    {
      '1': 'keys_vals',
      '3': 10,
      '4': 3,
      '5': 5,
      '8': {'2': true},
      '10': 'keysVals',
    },
  ],
};

/// Descriptor for `DenseNodes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List denseNodesDescriptor = $convert.base64Decode(
    'CgpEZW5zZU5vZGVzEhIKAmlkGAEgAygSQgIQAVICaWQSLwoJZGVuc2VpbmZvGAUgASgLMhEuT1'
    'NNUEJGLkRlbnNlSW5mb1IJZGVuc2VpbmZvEhQKA2xhdBgIIAMoEkICEAFSA2xhdBIUCgNsb24Y'
    'CSADKBJCAhABUgNsb24SHwoJa2V5c192YWxzGAogAygFQgIQAVIIa2V5c1ZhbHM=');

@$core.Deprecated('Use wayDescriptor instead')
const Way$json = {
  '1': 'Way',
  '2': [
    {'1': 'id', '3': 1, '4': 2, '5': 3, '10': 'id'},
    {
      '1': 'keys',
      '3': 2,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'keys',
    },
    {
      '1': 'vals',
      '3': 3,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'vals',
    },
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.OSMPBF.Info', '10': 'info'},
    {
      '1': 'refs',
      '3': 8,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'refs',
    },
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

/// Descriptor for `Way`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wayDescriptor = $convert.base64Decode(
    'CgNXYXkSDgoCaWQYASACKANSAmlkEhYKBGtleXMYAiADKA1CAhABUgRrZXlzEhYKBHZhbHMYAy'
    'ADKA1CAhABUgR2YWxzEiAKBGluZm8YBCABKAsyDC5PU01QQkYuSW5mb1IEaW5mbxIWCgRyZWZz'
    'GAggAygSQgIQAVIEcmVmcxIUCgNsYXQYCSADKBJCAhABUgNsYXQSFAoDbG9uGAogAygSQgIQAV'
    'IDbG9u');

@$core.Deprecated('Use relationDescriptor instead')
const Relation$json = {
  '1': 'Relation',
  '2': [
    {'1': 'id', '3': 1, '4': 2, '5': 3, '10': 'id'},
    {
      '1': 'keys',
      '3': 2,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'keys',
    },
    {
      '1': 'vals',
      '3': 3,
      '4': 3,
      '5': 13,
      '8': {'2': true},
      '10': 'vals',
    },
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.OSMPBF.Info', '10': 'info'},
    {
      '1': 'roles_sid',
      '3': 8,
      '4': 3,
      '5': 5,
      '8': {'2': true},
      '10': 'rolesSid',
    },
    {
      '1': 'memids',
      '3': 9,
      '4': 3,
      '5': 18,
      '8': {'2': true},
      '10': 'memids',
    },
    {
      '1': 'types',
      '3': 10,
      '4': 3,
      '5': 14,
      '6': '.OSMPBF.Relation.MemberType',
      '8': {'2': true},
      '10': 'types',
    },
  ],
  '4': [Relation_MemberType$json],
};

@$core.Deprecated('Use relationDescriptor instead')
const Relation_MemberType$json = {
  '1': 'MemberType',
  '2': [
    {'1': 'NODE', '2': 0},
    {'1': 'WAY', '2': 1},
    {'1': 'RELATION', '2': 2},
  ],
};

/// Descriptor for `Relation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relationDescriptor = $convert.base64Decode(
    'CghSZWxhdGlvbhIOCgJpZBgBIAIoA1ICaWQSFgoEa2V5cxgCIAMoDUICEAFSBGtleXMSFgoEdm'
    'FscxgDIAMoDUICEAFSBHZhbHMSIAoEaW5mbxgEIAEoCzIMLk9TTVBCRi5JbmZvUgRpbmZvEh8K'
    'CXJvbGVzX3NpZBgIIAMoBUICEAFSCHJvbGVzU2lkEhoKBm1lbWlkcxgJIAMoEkICEAFSBm1lbW'
    'lkcxI1CgV0eXBlcxgKIAMoDjIbLk9TTVBCRi5SZWxhdGlvbi5NZW1iZXJUeXBlQgIQAVIFdHlw'
    'ZXMiLQoKTWVtYmVyVHlwZRIICgROT0RFEAASBwoDV0FZEAESDAoIUkVMQVRJT04QAg==');
