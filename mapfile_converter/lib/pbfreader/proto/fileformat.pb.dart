//
//  Generated code. Do not modify.
//  source: lib/proto/fileformat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Blob extends $pb.GeneratedMessage {
  factory Blob({
    $core.List<$core.int>? raw,
    $core.int? rawSize,
    $core.List<$core.int>? zlibData,
    $core.List<$core.int>? lzmaData,
    @$core.Deprecated('This field is deprecated.')
    $core.List<$core.int>? oBSOLETEBzip2Data,
  }) {
    final $result = create();
    if (raw != null) {
      $result.raw = raw;
    }
    if (rawSize != null) {
      $result.rawSize = rawSize;
    }
    if (zlibData != null) {
      $result.zlibData = zlibData;
    }
    if (lzmaData != null) {
      $result.lzmaData = lzmaData;
    }
    if (oBSOLETEBzip2Data != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.oBSOLETEBzip2Data = oBSOLETEBzip2Data;
    }
    return $result;
  }
  Blob._() : super();
  factory Blob.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Blob.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Blob',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'raw', $pb.PbFieldType.OY)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'rawSize', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'zlibData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'lzmaData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'OBSOLETEBzip2Data', $pb.PbFieldType.OY,
        protoName: 'OBSOLETE_bzip2_data')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Blob clone() => Blob()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Blob copyWith(void Function(Blob) updates) =>
      super.copyWith((message) => updates(message as Blob)) as Blob;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Blob create() => Blob._();
  Blob createEmptyInstance() => create();
  static $pb.PbList<Blob> createRepeated() => $pb.PbList<Blob>();
  @$core.pragma('dart2js:noInline')
  static Blob getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Blob>(create);
  static Blob? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get raw => $_getN(0);
  @$pb.TagNumber(1)
  set raw($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRaw() => $_has(0);
  @$pb.TagNumber(1)
  void clearRaw() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get rawSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set rawSize($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRawSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawSize() => clearField(2);

  /// Possible compressed versions of the data.
  @$pb.TagNumber(3)
  $core.List<$core.int> get zlibData => $_getN(2);
  @$pb.TagNumber(3)
  set zlibData($core.List<$core.int> v) {
    $_setBytes(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasZlibData() => $_has(2);
  @$pb.TagNumber(3)
  void clearZlibData() => clearField(3);

  /// PROPOSED feature for LZMA compressed data. SUPPORT IS NOT REQUIRED.
  @$pb.TagNumber(4)
  $core.List<$core.int> get lzmaData => $_getN(3);
  @$pb.TagNumber(4)
  set lzmaData($core.List<$core.int> v) {
    $_setBytes(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLzmaData() => $_has(3);
  @$pb.TagNumber(4)
  void clearLzmaData() => clearField(4);

  /// Formerly used for bzip2 compressed data. Depreciated in 2010.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.List<$core.int> get oBSOLETEBzip2Data => $_getN(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  set oBSOLETEBzip2Data($core.List<$core.int> v) {
    $_setBytes(4, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  $core.bool hasOBSOLETEBzip2Data() => $_has(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(5)
  void clearOBSOLETEBzip2Data() => clearField(5);
}

class BlobHeader extends $pb.GeneratedMessage {
  factory BlobHeader({
    $core.String? type,
    $core.List<$core.int>? indexdata,
    $core.int? datasize,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (indexdata != null) {
      $result.indexdata = indexdata;
    }
    if (datasize != null) {
      $result.datasize = datasize;
    }
    return $result;
  }
  BlobHeader._() : super();
  factory BlobHeader.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BlobHeader.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BlobHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..aQS(1, _omitFieldNames ? '' : 'type')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'indexdata', $pb.PbFieldType.OY)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'datasize', $pb.PbFieldType.Q3);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BlobHeader clone() => BlobHeader()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BlobHeader copyWith(void Function(BlobHeader) updates) =>
      super.copyWith((message) => updates(message as BlobHeader)) as BlobHeader;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlobHeader create() => BlobHeader._();
  BlobHeader createEmptyInstance() => create();
  static $pb.PbList<BlobHeader> createRepeated() => $pb.PbList<BlobHeader>();
  @$core.pragma('dart2js:noInline')
  static BlobHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BlobHeader>(create);
  static BlobHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get indexdata => $_getN(1);
  @$pb.TagNumber(2)
  set indexdata($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIndexdata() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndexdata() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get datasize => $_getIZ(2);
  @$pb.TagNumber(3)
  set datasize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDatasize() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatasize() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
