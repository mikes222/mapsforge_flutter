// This is a generated file - do not edit.
//
// Generated from lib/pbfproto/fileformat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Blob extends $pb.GeneratedMessage {
  factory Blob({
    $core.List<$core.int>? raw,
    $core.int? rawSize,
    $core.List<$core.int>? zlibData,
    $core.List<$core.int>? lzmaData,
    @$core.Deprecated('This field is deprecated.')
    $core.List<$core.int>? oBSOLETEBzip2Data,
  }) {
    final result = create();
    if (raw != null) result.raw = raw;
    if (rawSize != null) result.rawSize = rawSize;
    if (zlibData != null) result.zlibData = zlibData;
    if (lzmaData != null) result.lzmaData = lzmaData;
    if (oBSOLETEBzip2Data != null) result.oBSOLETEBzip2Data = oBSOLETEBzip2Data;
    return result;
  }

  Blob._();

  factory Blob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Blob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Blob',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'raw', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'rawSize')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'zlibData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'lzmaData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'OBSOLETEBzip2Data', $pb.PbFieldType.OY,
        protoName: 'OBSOLETE_bzip2_data')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Blob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Blob copyWith(void Function(Blob) updates) =>
      super.copyWith((message) => updates(message as Blob)) as Blob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Blob create() => Blob._();
  @$core.override
  Blob createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Blob getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Blob>(create);
  static Blob? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get raw => $_getN(0);
  @$pb.TagNumber(1)
  set raw($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRaw() => $_has(0);
  @$pb.TagNumber(1)
  void clearRaw() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rawSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set rawSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawSize() => $_clearField(2);

  /// Possible compressed versions of the data.
  @$pb.TagNumber(3)
  $core.List<$core.int> get zlibData => $_getN(2);
  @$pb.TagNumber(3)
  set zlibData($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZlibData() => $_has(2);
  @$pb.TagNumber(3)
  void clearZlibData() => $_clearField(3);

  /// PROPOSED feature for LZMA compressed data. SUPPORT IS NOT REQUIRED.
  @$pb.TagNumber(4)
  $core.List<$core.int> get lzmaData => $_getN(3);
  @$pb.TagNumber(4)
  set lzmaData($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLzmaData() => $_has(3);
  @$pb.TagNumber(4)
  void clearLzmaData() => $_clearField(4);

  /// Formerly used for bzip2 compressed data. Depreciated in 2010.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.List<$core.int> get oBSOLETEBzip2Data => $_getN(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  set oBSOLETEBzip2Data($core.List<$core.int> value) => $_setBytes(4, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.bool hasOBSOLETEBzip2Data() => $_has(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  void clearOBSOLETEBzip2Data() => $_clearField(5);
}

class BlobHeader extends $pb.GeneratedMessage {
  factory BlobHeader({
    $core.String? type,
    $core.List<$core.int>? indexdata,
    $core.int? datasize,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (indexdata != null) result.indexdata = indexdata;
    if (datasize != null) result.datasize = datasize;
    return result;
  }

  BlobHeader._();

  factory BlobHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BlobHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BlobHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..aQS(1, _omitFieldNames ? '' : 'type')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'indexdata', $pb.PbFieldType.OY)
    ..aI(3, _omitFieldNames ? '' : 'datasize', fieldType: $pb.PbFieldType.Q3);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlobHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlobHeader copyWith(void Function(BlobHeader) updates) =>
      super.copyWith((message) => updates(message as BlobHeader)) as BlobHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlobHeader create() => BlobHeader._();
  @$core.override
  BlobHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BlobHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BlobHeader>(create);
  static BlobHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get indexdata => $_getN(1);
  @$pb.TagNumber(2)
  set indexdata($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndexdata() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndexdata() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get datasize => $_getIZ(2);
  @$pb.TagNumber(3)
  set datasize($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDatasize() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatasize() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
