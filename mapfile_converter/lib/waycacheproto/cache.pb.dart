//
//  Generated code. Do not modify.
//  source: lib/pbfreader/waycacheproto/cache.pbfproto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CacheWay extends $pb.GeneratedMessage {
  factory CacheWay({
    $core.Iterable<$fixnum.Int64>? lat,
    $core.Iterable<$fixnum.Int64>? lon,
  }) {
    final $result = create();
    if (lat != null) {
      $result.lat.addAll(lat);
    }
    if (lon != null) {
      $result.lon.addAll(lon);
    }
    return $result;
  }
  CacheWay._() : super();
  factory CacheWay.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CacheWay.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CacheWay', createEmptyInstance: create)
    ..p<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(10, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.KS6)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CacheWay clone() => CacheWay()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CacheWay copyWith(void Function(CacheWay) updates) => super.copyWith((message) => updates(message as CacheWay)) as CacheWay;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheWay create() => CacheWay._();
  CacheWay createEmptyInstance() => create();
  static $pb.PbList<CacheWay> createRepeated() => $pb.PbList<CacheWay>();
  @$core.pragma('dart2js:noInline')
  static CacheWay getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheWay>(create);
  static CacheWay? _defaultInstance;

  @$pb.TagNumber(9)
  $pb.PbList<$fixnum.Int64> get lat => $_getList(0);

  @$pb.TagNumber(10)
  $pb.PbList<$fixnum.Int64> get lon => $_getList(1);
}

class CacheLabel extends $pb.GeneratedMessage {
  factory CacheLabel({
    $fixnum.Int64? lat,
    $fixnum.Int64? lon,
  }) {
    final $result = create();
    if (lat != null) {
      $result.lat = lat;
    }
    if (lon != null) {
      $result.lon = lon;
    }
    return $result;
  }
  CacheLabel._() : super();
  factory CacheLabel.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CacheLabel.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CacheLabel', createEmptyInstance: create)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.QS6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.QS6, defaultOrMaker: $fixnum.Int64.ZERO);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CacheLabel clone() => CacheLabel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CacheLabel copyWith(void Function(CacheLabel) updates) => super.copyWith((message) => updates(message as CacheLabel)) as CacheLabel;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheLabel create() => CacheLabel._();
  CacheLabel createEmptyInstance() => create();
  static $pb.PbList<CacheLabel> createRepeated() => $pb.PbList<CacheLabel>();
  @$core.pragma('dart2js:noInline')
  static CacheLabel getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheLabel>(create);
  static CacheLabel? _defaultInstance;

  @$pb.TagNumber(8)
  $fixnum.Int64 get lat => $_getI64(0);
  @$pb.TagNumber(8)
  set lat($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(8)
  void clearLat() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lon => $_getI64(1);
  @$pb.TagNumber(9)
  set lon($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasLon() => $_has(1);
  @$pb.TagNumber(9)
  void clearLon() => $_clearField(9);
}

class CacheWayholder extends $pb.GeneratedMessage {
  factory CacheWayholder({
    $core.Iterable<$core.String>? tagkeys,
    $core.Iterable<$core.String>? tagvals,
    $core.Iterable<CacheWay>? innerways,
    $core.Iterable<CacheWay>? closedways,
    $core.Iterable<CacheWay>? openways,
    CacheLabel? label,
    $core.int? layer,
    $core.int? tileBitmask,
    $core.bool? mergedWithOtherWay,
  }) {
    final $result = create();
    if (tagkeys != null) {
      $result.tagkeys.addAll(tagkeys);
    }
    if (tagvals != null) {
      $result.tagvals.addAll(tagvals);
    }
    if (innerways != null) {
      $result.innerways.addAll(innerways);
    }
    if (closedways != null) {
      $result.closedways.addAll(closedways);
    }
    if (openways != null) {
      $result.openways.addAll(openways);
    }
    if (label != null) {
      $result.label = label;
    }
    if (layer != null) {
      $result.layer = layer;
    }
    if (tileBitmask != null) {
      $result.tileBitmask = tileBitmask;
    }
    if (mergedWithOtherWay != null) {
      $result.mergedWithOtherWay = mergedWithOtherWay;
    }
    return $result;
  }
  CacheWayholder._() : super();
  factory CacheWayholder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CacheWayholder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CacheWayholder', createEmptyInstance: create)
    ..pPS(2, _omitFieldNames ? '' : 'tagkeys')
    ..pPS(3, _omitFieldNames ? '' : 'tagvals')
    ..pc<CacheWay>(4, _omitFieldNames ? '' : 'innerways', $pb.PbFieldType.PM, subBuilder: CacheWay.create)
    ..pc<CacheWay>(5, _omitFieldNames ? '' : 'closedways', $pb.PbFieldType.PM, subBuilder: CacheWay.create)
    ..pc<CacheWay>(6, _omitFieldNames ? '' : 'openways', $pb.PbFieldType.PM, subBuilder: CacheWay.create)
    ..aOM<CacheLabel>(11, _omitFieldNames ? '' : 'label', subBuilder: CacheLabel.create)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'layer', $pb.PbFieldType.Q3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'tileBitmask', $pb.PbFieldType.Q3, protoName: 'tileBitmask')
    ..a<$core.bool>(15, _omitFieldNames ? '' : 'mergedWithOtherWay', $pb.PbFieldType.QB, protoName: 'mergedWithOtherWay');

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CacheWayholder clone() => CacheWayholder()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CacheWayholder copyWith(void Function(CacheWayholder) updates) => super.copyWith((message) => updates(message as CacheWayholder)) as CacheWayholder;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheWayholder create() => CacheWayholder._();
  CacheWayholder createEmptyInstance() => create();
  static $pb.PbList<CacheWayholder> createRepeated() => $pb.PbList<CacheWayholder>();
  @$core.pragma('dart2js:noInline')
  static CacheWayholder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheWayholder>(create);
  static CacheWayholder? _defaultInstance;

  /// Parallel arrays for tags
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get tagkeys => $_getList(0);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get tagvals => $_getList(1);

  @$pb.TagNumber(4)
  $pb.PbList<CacheWay> get innerways => $_getList(2);

  @$pb.TagNumber(5)
  $pb.PbList<CacheWay> get closedways => $_getList(3);

  @$pb.TagNumber(6)
  $pb.PbList<CacheWay> get openways => $_getList(4);

  @$pb.TagNumber(11)
  CacheLabel get label => $_getN(5);
  @$pb.TagNumber(11)
  set label(CacheLabel v) {
    $_setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(11)
  void clearLabel() => $_clearField(11);
  @$pb.TagNumber(11)
  CacheLabel ensureLabel() => $_ensure(5);

  @$pb.TagNumber(13)
  $core.int get layer => $_getIZ(6);
  @$pb.TagNumber(13)
  set layer($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasLayer() => $_has(6);
  @$pb.TagNumber(13)
  void clearLayer() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get tileBitmask => $_getIZ(7);
  @$pb.TagNumber(14)
  set tileBitmask($core.int v) {
    $_setSignedInt32(7, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasTileBitmask() => $_has(7);
  @$pb.TagNumber(14)
  void clearTileBitmask() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get mergedWithOtherWay => $_getBF(8);
  @$pb.TagNumber(15)
  set mergedWithOtherWay($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasMergedWithOtherWay() => $_has(8);
  @$pb.TagNumber(15)
  void clearMergedWithOtherWay() => $_clearField(15);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
