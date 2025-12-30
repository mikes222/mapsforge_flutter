// This is a generated file - do not edit.
//
// Generated from lib/waycacheproto/osm_waycache.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CacheWay extends $pb.GeneratedMessage {
  factory CacheWay({
    $core.Iterable<$fixnum.Int64>? lat,
    $core.Iterable<$fixnum.Int64>? lon,
  }) {
    final result = create();
    if (lat != null) result.lat.addAll(lat);
    if (lon != null) result.lon.addAll(lon);
    return result;
  }

  CacheWay._();

  factory CacheWay.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CacheWay.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CacheWay',
      createEmptyInstance: create)
    ..p<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(10, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.KS6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheWay clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheWay copyWith(void Function(CacheWay) updates) =>
      super.copyWith((message) => updates(message as CacheWay)) as CacheWay;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheWay create() => CacheWay._();
  @$core.override
  CacheWay createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CacheWay getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheWay>(create);
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
    final result = create();
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    return result;
  }

  CacheLabel._();

  factory CacheLabel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CacheLabel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CacheLabel',
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheLabel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheLabel copyWith(void Function(CacheLabel) updates) =>
      super.copyWith((message) => updates(message as CacheLabel)) as CacheLabel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheLabel create() => CacheLabel._();
  @$core.override
  CacheLabel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CacheLabel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CacheLabel>(create);
  static CacheLabel? _defaultInstance;

  @$pb.TagNumber(8)
  $fixnum.Int64 get lat => $_getI64(0);
  @$pb.TagNumber(8)
  set lat($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(8)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(8)
  void clearLat() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lon => $_getI64(1);
  @$pb.TagNumber(9)
  set lon($fixnum.Int64 value) => $_setInt64(1, value);
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
    $core.bool? mergedWithOtherWay,
    $core.Iterable<$core.String>? normalizedkeys,
    $core.Iterable<$core.String>? normalizedvals,
  }) {
    final result = create();
    if (tagkeys != null) result.tagkeys.addAll(tagkeys);
    if (tagvals != null) result.tagvals.addAll(tagvals);
    if (innerways != null) result.innerways.addAll(innerways);
    if (closedways != null) result.closedways.addAll(closedways);
    if (openways != null) result.openways.addAll(openways);
    if (label != null) result.label = label;
    if (mergedWithOtherWay != null)
      result.mergedWithOtherWay = mergedWithOtherWay;
    if (normalizedkeys != null) result.normalizedkeys.addAll(normalizedkeys);
    if (normalizedvals != null) result.normalizedvals.addAll(normalizedvals);
    return result;
  }

  CacheWayholder._();

  factory CacheWayholder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CacheWayholder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CacheWayholder',
      createEmptyInstance: create)
    ..pPS(2, _omitFieldNames ? '' : 'tagkeys')
    ..pPS(3, _omitFieldNames ? '' : 'tagvals')
    ..pPM<CacheWay>(4, _omitFieldNames ? '' : 'innerways',
        subBuilder: CacheWay.create)
    ..pPM<CacheWay>(5, _omitFieldNames ? '' : 'closedways',
        subBuilder: CacheWay.create)
    ..pPM<CacheWay>(6, _omitFieldNames ? '' : 'openways',
        subBuilder: CacheWay.create)
    ..aOM<CacheLabel>(11, _omitFieldNames ? '' : 'label',
        subBuilder: CacheLabel.create)
    ..a<$core.bool>(
        15, _omitFieldNames ? '' : 'mergedWithOtherWay', $pb.PbFieldType.QB,
        protoName: 'mergedWithOtherWay')
    ..pPS(16, _omitFieldNames ? '' : 'normalizedkeys')
    ..pPS(17, _omitFieldNames ? '' : 'normalizedvals');

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheWayholder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CacheWayholder copyWith(void Function(CacheWayholder) updates) =>
      super.copyWith((message) => updates(message as CacheWayholder))
          as CacheWayholder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheWayholder create() => CacheWayholder._();
  @$core.override
  CacheWayholder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CacheWayholder getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CacheWayholder>(create);
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
  set label(CacheLabel value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(11)
  void clearLabel() => $_clearField(11);
  @$pb.TagNumber(11)
  CacheLabel ensureLabel() => $_ensure(5);

  @$pb.TagNumber(15)
  $core.bool get mergedWithOtherWay => $_getBF(6);
  @$pb.TagNumber(15)
  set mergedWithOtherWay($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(15)
  $core.bool hasMergedWithOtherWay() => $_has(6);
  @$pb.TagNumber(15)
  void clearMergedWithOtherWay() => $_clearField(15);

  /// Parallel arrays for tags
  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get normalizedkeys => $_getList(7);

  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get normalizedvals => $_getList(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
