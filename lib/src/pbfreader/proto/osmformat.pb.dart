//
//  Generated code. Do not modify.
//  source: lib/proto/osmformat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'osmformat.pbenum.dart';

export 'osmformat.pbenum.dart';

class HeaderBlock extends $pb.GeneratedMessage {
  factory HeaderBlock({
    HeaderBBox? bbox,
    $core.Iterable<$core.String>? requiredFeatures,
    $core.Iterable<$core.String>? optionalFeatures,
    $core.String? writingprogram,
    $core.String? source,
    $fixnum.Int64? osmosisReplicationTimestamp,
    $fixnum.Int64? osmosisReplicationSequenceNumber,
    $core.String? osmosisReplicationBaseUrl,
  }) {
    final $result = create();
    if (bbox != null) {
      $result.bbox = bbox;
    }
    if (requiredFeatures != null) {
      $result.requiredFeatures.addAll(requiredFeatures);
    }
    if (optionalFeatures != null) {
      $result.optionalFeatures.addAll(optionalFeatures);
    }
    if (writingprogram != null) {
      $result.writingprogram = writingprogram;
    }
    if (source != null) {
      $result.source = source;
    }
    if (osmosisReplicationTimestamp != null) {
      $result.osmosisReplicationTimestamp = osmosisReplicationTimestamp;
    }
    if (osmosisReplicationSequenceNumber != null) {
      $result.osmosisReplicationSequenceNumber =
          osmosisReplicationSequenceNumber;
    }
    if (osmosisReplicationBaseUrl != null) {
      $result.osmosisReplicationBaseUrl = osmosisReplicationBaseUrl;
    }
    return $result;
  }
  HeaderBlock._() : super();
  factory HeaderBlock.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HeaderBlock.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeaderBlock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..aOM<HeaderBBox>(1, _omitFieldNames ? '' : 'bbox',
        subBuilder: HeaderBBox.create)
    ..pPS(4, _omitFieldNames ? '' : 'requiredFeatures')
    ..pPS(5, _omitFieldNames ? '' : 'optionalFeatures')
    ..aOS(16, _omitFieldNames ? '' : 'writingprogram')
    ..aOS(17, _omitFieldNames ? '' : 'source')
    ..aInt64(32, _omitFieldNames ? '' : 'osmosisReplicationTimestamp')
    ..aInt64(33, _omitFieldNames ? '' : 'osmosisReplicationSequenceNumber')
    ..aOS(34, _omitFieldNames ? '' : 'osmosisReplicationBaseUrl');

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HeaderBlock clone() => HeaderBlock()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HeaderBlock copyWith(void Function(HeaderBlock) updates) =>
      super.copyWith((message) => updates(message as HeaderBlock))
          as HeaderBlock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeaderBlock create() => HeaderBlock._();
  HeaderBlock createEmptyInstance() => create();
  static $pb.PbList<HeaderBlock> createRepeated() => $pb.PbList<HeaderBlock>();
  @$core.pragma('dart2js:noInline')
  static HeaderBlock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeaderBlock>(create);
  static HeaderBlock? _defaultInstance;

  @$pb.TagNumber(1)
  HeaderBBox get bbox => $_getN(0);
  @$pb.TagNumber(1)
  set bbox(HeaderBBox v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBbox() => $_has(0);
  @$pb.TagNumber(1)
  void clearBbox() => clearField(1);
  @$pb.TagNumber(1)
  HeaderBBox ensureBbox() => $_ensure(0);

  /// Additional tags to aid in parsing this dataset
  @$pb.TagNumber(4)
  $core.List<$core.String> get requiredFeatures => $_getList(1);

  @$pb.TagNumber(5)
  $core.List<$core.String> get optionalFeatures => $_getList(2);

  @$pb.TagNumber(16)
  $core.String get writingprogram => $_getSZ(3);
  @$pb.TagNumber(16)
  set writingprogram($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasWritingprogram() => $_has(3);
  @$pb.TagNumber(16)
  void clearWritingprogram() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get source => $_getSZ(4);
  @$pb.TagNumber(17)
  set source($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(17)
  void clearSource() => clearField(17);

  /// Replication timestamp, expressed in seconds since the epoch,
  /// otherwise the same value as in the "timestamp=..." field
  /// in the state.txt file used by Osmosis.
  @$pb.TagNumber(32)
  $fixnum.Int64 get osmosisReplicationTimestamp => $_getI64(5);
  @$pb.TagNumber(32)
  set osmosisReplicationTimestamp($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(32)
  $core.bool hasOsmosisReplicationTimestamp() => $_has(5);
  @$pb.TagNumber(32)
  void clearOsmosisReplicationTimestamp() => clearField(32);

  /// Replication sequence number (sequenceNumber in state.txt).
  @$pb.TagNumber(33)
  $fixnum.Int64 get osmosisReplicationSequenceNumber => $_getI64(6);
  @$pb.TagNumber(33)
  set osmosisReplicationSequenceNumber($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasOsmosisReplicationSequenceNumber() => $_has(6);
  @$pb.TagNumber(33)
  void clearOsmosisReplicationSequenceNumber() => clearField(33);

  /// Replication base URL (from Osmosis' configuration.txt file).
  @$pb.TagNumber(34)
  $core.String get osmosisReplicationBaseUrl => $_getSZ(7);
  @$pb.TagNumber(34)
  set osmosisReplicationBaseUrl($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(34)
  $core.bool hasOsmosisReplicationBaseUrl() => $_has(7);
  @$pb.TagNumber(34)
  void clearOsmosisReplicationBaseUrl() => clearField(34);
}

class HeaderBBox extends $pb.GeneratedMessage {
  factory HeaderBBox({
    $fixnum.Int64? left,
    $fixnum.Int64? right,
    $fixnum.Int64? top,
    $fixnum.Int64? bottom,
  }) {
    final $result = create();
    if (left != null) {
      $result.left = left;
    }
    if (right != null) {
      $result.right = right;
    }
    if (top != null) {
      $result.top = top;
    }
    if (bottom != null) {
      $result.bottom = bottom;
    }
    return $result;
  }
  HeaderBBox._() : super();
  factory HeaderBBox.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HeaderBBox.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeaderBBox',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'left', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'right', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'top', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bottom', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HeaderBBox clone() => HeaderBBox()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HeaderBBox copyWith(void Function(HeaderBBox) updates) =>
      super.copyWith((message) => updates(message as HeaderBBox)) as HeaderBBox;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeaderBBox create() => HeaderBBox._();
  HeaderBBox createEmptyInstance() => create();
  static $pb.PbList<HeaderBBox> createRepeated() => $pb.PbList<HeaderBBox>();
  @$core.pragma('dart2js:noInline')
  static HeaderBBox getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeaderBBox>(create);
  static HeaderBBox? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get left => $_getI64(0);
  @$pb.TagNumber(1)
  set left($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLeft() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeft() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get right => $_getI64(1);
  @$pb.TagNumber(2)
  set right($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRight() => $_has(1);
  @$pb.TagNumber(2)
  void clearRight() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get top => $_getI64(2);
  @$pb.TagNumber(3)
  set top($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTop() => $_has(2);
  @$pb.TagNumber(3)
  void clearTop() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bottom => $_getI64(3);
  @$pb.TagNumber(4)
  set bottom($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasBottom() => $_has(3);
  @$pb.TagNumber(4)
  void clearBottom() => clearField(4);
}

class PrimitiveBlock extends $pb.GeneratedMessage {
  factory PrimitiveBlock({
    StringTable? stringtable,
    $core.Iterable<PrimitiveGroup>? primitivegroup,
    $core.int? granularity,
    $core.int? dateGranularity,
    $fixnum.Int64? latOffset,
    $fixnum.Int64? lonOffset,
  }) {
    final $result = create();
    if (stringtable != null) {
      $result.stringtable = stringtable;
    }
    if (primitivegroup != null) {
      $result.primitivegroup.addAll(primitivegroup);
    }
    if (granularity != null) {
      $result.granularity = granularity;
    }
    if (dateGranularity != null) {
      $result.dateGranularity = dateGranularity;
    }
    if (latOffset != null) {
      $result.latOffset = latOffset;
    }
    if (lonOffset != null) {
      $result.lonOffset = lonOffset;
    }
    return $result;
  }
  PrimitiveBlock._() : super();
  factory PrimitiveBlock.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PrimitiveBlock.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrimitiveBlock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..aQM<StringTable>(1, _omitFieldNames ? '' : 'stringtable',
        subBuilder: StringTable.create)
    ..pc<PrimitiveGroup>(
        2, _omitFieldNames ? '' : 'primitivegroup', $pb.PbFieldType.PM,
        subBuilder: PrimitiveGroup.create)
    ..a<$core.int>(17, _omitFieldNames ? '' : 'granularity', $pb.PbFieldType.O3,
        defaultOrMaker: 100)
    ..a<$core.int>(
        18, _omitFieldNames ? '' : 'dateGranularity', $pb.PbFieldType.O3,
        defaultOrMaker: 1000)
    ..aInt64(19, _omitFieldNames ? '' : 'latOffset')
    ..aInt64(20, _omitFieldNames ? '' : 'lonOffset');

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PrimitiveBlock clone() => PrimitiveBlock()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PrimitiveBlock copyWith(void Function(PrimitiveBlock) updates) =>
      super.copyWith((message) => updates(message as PrimitiveBlock))
          as PrimitiveBlock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrimitiveBlock create() => PrimitiveBlock._();
  PrimitiveBlock createEmptyInstance() => create();
  static $pb.PbList<PrimitiveBlock> createRepeated() =>
      $pb.PbList<PrimitiveBlock>();
  @$core.pragma('dart2js:noInline')
  static PrimitiveBlock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrimitiveBlock>(create);
  static PrimitiveBlock? _defaultInstance;

  @$pb.TagNumber(1)
  StringTable get stringtable => $_getN(0);
  @$pb.TagNumber(1)
  set stringtable(StringTable v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStringtable() => $_has(0);
  @$pb.TagNumber(1)
  void clearStringtable() => clearField(1);
  @$pb.TagNumber(1)
  StringTable ensureStringtable() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<PrimitiveGroup> get primitivegroup => $_getList(1);

  /// Granularity, units of nanodegrees, used to store coordinates in this block.
  @$pb.TagNumber(17)
  $core.int get granularity => $_getI(2, 100);
  @$pb.TagNumber(17)
  set granularity($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasGranularity() => $_has(2);
  @$pb.TagNumber(17)
  void clearGranularity() => clearField(17);

  /// Granularity of dates, normally represented in units of milliseconds since the 1970 epoch.
  @$pb.TagNumber(18)
  $core.int get dateGranularity => $_getI(3, 1000);
  @$pb.TagNumber(18)
  set dateGranularity($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasDateGranularity() => $_has(3);
  @$pb.TagNumber(18)
  void clearDateGranularity() => clearField(18);

  /// Offset value between the output coordinates and the granularity grid in units of nanodegrees.
  @$pb.TagNumber(19)
  $fixnum.Int64 get latOffset => $_getI64(4);
  @$pb.TagNumber(19)
  set latOffset($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(19)
  $core.bool hasLatOffset() => $_has(4);
  @$pb.TagNumber(19)
  void clearLatOffset() => clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get lonOffset => $_getI64(5);
  @$pb.TagNumber(20)
  set lonOffset($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasLonOffset() => $_has(5);
  @$pb.TagNumber(20)
  void clearLonOffset() => clearField(20);
}

/// Group of OSMPrimitives. All primitives in a group must be the same type.
class PrimitiveGroup extends $pb.GeneratedMessage {
  factory PrimitiveGroup({
    $core.Iterable<Node>? nodes,
    DenseNodes? dense,
    $core.Iterable<Way>? ways,
    $core.Iterable<Relation>? relations,
    $core.Iterable<ChangeSet>? changesets,
  }) {
    final $result = create();
    if (nodes != null) {
      $result.nodes.addAll(nodes);
    }
    if (dense != null) {
      $result.dense = dense;
    }
    if (ways != null) {
      $result.ways.addAll(ways);
    }
    if (relations != null) {
      $result.relations.addAll(relations);
    }
    if (changesets != null) {
      $result.changesets.addAll(changesets);
    }
    return $result;
  }
  PrimitiveGroup._() : super();
  factory PrimitiveGroup.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PrimitiveGroup.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrimitiveGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..pc<Node>(1, _omitFieldNames ? '' : 'nodes', $pb.PbFieldType.PM,
        subBuilder: Node.create)
    ..aOM<DenseNodes>(2, _omitFieldNames ? '' : 'dense',
        subBuilder: DenseNodes.create)
    ..pc<Way>(3, _omitFieldNames ? '' : 'ways', $pb.PbFieldType.PM,
        subBuilder: Way.create)
    ..pc<Relation>(4, _omitFieldNames ? '' : 'relations', $pb.PbFieldType.PM,
        subBuilder: Relation.create)
    ..pc<ChangeSet>(5, _omitFieldNames ? '' : 'changesets', $pb.PbFieldType.PM,
        subBuilder: ChangeSet.create);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PrimitiveGroup clone() => PrimitiveGroup()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PrimitiveGroup copyWith(void Function(PrimitiveGroup) updates) =>
      super.copyWith((message) => updates(message as PrimitiveGroup))
          as PrimitiveGroup;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrimitiveGroup create() => PrimitiveGroup._();
  PrimitiveGroup createEmptyInstance() => create();
  static $pb.PbList<PrimitiveGroup> createRepeated() =>
      $pb.PbList<PrimitiveGroup>();
  @$core.pragma('dart2js:noInline')
  static PrimitiveGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrimitiveGroup>(create);
  static PrimitiveGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Node> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  DenseNodes get dense => $_getN(1);
  @$pb.TagNumber(2)
  set dense(DenseNodes v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDense() => $_has(1);
  @$pb.TagNumber(2)
  void clearDense() => clearField(2);
  @$pb.TagNumber(2)
  DenseNodes ensureDense() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<Way> get ways => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<Relation> get relations => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<ChangeSet> get changesets => $_getList(4);
}

/// * String table, contains the common strings in each block.
///
/// Note that we reserve index '0' as a delimiter, so the entry at that
/// index in the table is ALWAYS blank and unused.
class StringTable extends $pb.GeneratedMessage {
  factory StringTable({
    $core.Iterable<$core.List<$core.int>>? s,
  }) {
    final $result = create();
    if (s != null) {
      $result.s.addAll(s);
    }
    return $result;
  }
  StringTable._() : super();
  factory StringTable.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StringTable.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StringTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 's', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StringTable clone() => StringTable()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StringTable copyWith(void Function(StringTable) updates) =>
      super.copyWith((message) => updates(message as StringTable))
          as StringTable;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringTable create() => StringTable._();
  StringTable createEmptyInstance() => create();
  static $pb.PbList<StringTable> createRepeated() => $pb.PbList<StringTable>();
  @$core.pragma('dart2js:noInline')
  static StringTable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StringTable>(create);
  static StringTable? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get s => $_getList(0);
}

/// Optional metadata that may be included into each primitive.
class Info extends $pb.GeneratedMessage {
  factory Info({
    $core.int? version,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? changeset,
    $core.int? uid,
    $core.int? userSid,
    $core.bool? visible,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (changeset != null) {
      $result.changeset = changeset;
    }
    if (uid != null) {
      $result.uid = uid;
    }
    if (userSid != null) {
      $result.userSid = userSid;
    }
    if (visible != null) {
      $result.visible = visible;
    }
    return $result;
  }
  Info._() : super();
  factory Info.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Info.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Info',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3,
        defaultOrMaker: -1)
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aInt64(3, _omitFieldNames ? '' : 'changeset')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'userSid', $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'visible')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Info clone() => Info()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Info copyWith(void Function(Info) updates) =>
      super.copyWith((message) => updates(message as Info)) as Info;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Info create() => Info._();
  Info createEmptyInstance() => create();
  static $pb.PbList<Info> createRepeated() => $pb.PbList<Info>();
  @$core.pragma('dart2js:noInline')
  static Info getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Info>(create);
  static Info? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getI(0, -1);
  @$pb.TagNumber(1)
  set version($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get changeset => $_getI64(2);
  @$pb.TagNumber(3)
  set changeset($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasChangeset() => $_has(2);
  @$pb.TagNumber(3)
  void clearChangeset() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get uid => $_getIZ(3);
  @$pb.TagNumber(4)
  set uid($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasUid() => $_has(3);
  @$pb.TagNumber(4)
  void clearUid() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get userSid => $_getIZ(4);
  @$pb.TagNumber(5)
  set userSid($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasUserSid() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserSid() => clearField(5);

  /// The visible flag is used to store history information. It indicates that
  /// the current object version has been created by a delete operation on the
  /// OSM API.
  /// When a writer sets this flag, it MUST add a required_features tag with
  /// value "HistoricalInformation" to the HeaderBlock.
  /// If this flag is not available for some object it MUST be assumed to be
  /// true if the file has the required_features tag "HistoricalInformation"
  /// set.
  @$pb.TagNumber(6)
  $core.bool get visible => $_getBF(5);
  @$pb.TagNumber(6)
  set visible($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasVisible() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisible() => clearField(6);
}

/// * Optional metadata that may be included into each primitive. Special dense format used in DenseNodes.
class DenseInfo extends $pb.GeneratedMessage {
  factory DenseInfo({
    $core.Iterable<$core.int>? version,
    $core.Iterable<$fixnum.Int64>? timestamp,
    $core.Iterable<$fixnum.Int64>? changeset,
    $core.Iterable<$core.int>? uid,
    $core.Iterable<$core.int>? userSid,
    $core.Iterable<$core.bool>? visible,
  }) {
    final $result = create();
    if (version != null) {
      $result.version.addAll(version);
    }
    if (timestamp != null) {
      $result.timestamp.addAll(timestamp);
    }
    if (changeset != null) {
      $result.changeset.addAll(changeset);
    }
    if (uid != null) {
      $result.uid.addAll(uid);
    }
    if (userSid != null) {
      $result.userSid.addAll(userSid);
    }
    if (visible != null) {
      $result.visible.addAll(visible);
    }
    return $result;
  }
  DenseInfo._() : super();
  factory DenseInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DenseInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DenseInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.K3)
    ..p<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'changeset', $pb.PbFieldType.KS6)
    ..p<$core.int>(4, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.KS3)
    ..p<$core.int>(5, _omitFieldNames ? '' : 'userSid', $pb.PbFieldType.KS3)
    ..p<$core.bool>(6, _omitFieldNames ? '' : 'visible', $pb.PbFieldType.KB)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DenseInfo clone() => DenseInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DenseInfo copyWith(void Function(DenseInfo) updates) =>
      super.copyWith((message) => updates(message as DenseInfo)) as DenseInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DenseInfo create() => DenseInfo._();
  DenseInfo createEmptyInstance() => create();
  static $pb.PbList<DenseInfo> createRepeated() => $pb.PbList<DenseInfo>();
  @$core.pragma('dart2js:noInline')
  static DenseInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DenseInfo>(create);
  static DenseInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get version => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get timestamp => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$fixnum.Int64> get changeset => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get uid => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get userSid => $_getList(4);

  /// The visible flag is used to store history information. It indicates that
  /// the current object version has been created by a delete operation on the
  /// OSM API.
  /// When a writer sets this flag, it MUST add a required_features tag with
  /// value "HistoricalInformation" to the HeaderBlock.
  /// If this flag is not available for some object it MUST be assumed to be
  /// true if the file has the required_features tag "HistoricalInformation"
  /// set.
  @$pb.TagNumber(6)
  $core.List<$core.bool> get visible => $_getList(5);
}

/// This is kept for backwards compatibility but not used anywhere.
class ChangeSet extends $pb.GeneratedMessage {
  factory ChangeSet({
    $fixnum.Int64? id,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  ChangeSet._() : super();
  factory ChangeSet.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ChangeSet.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.Q6,
        defaultOrMaker: $fixnum.Int64.ZERO);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ChangeSet clone() => ChangeSet()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ChangeSet copyWith(void Function(ChangeSet) updates) =>
      super.copyWith((message) => updates(message as ChangeSet)) as ChangeSet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeSet create() => ChangeSet._();
  ChangeSet createEmptyInstance() => create();
  static $pb.PbList<ChangeSet> createRepeated() => $pb.PbList<ChangeSet>();
  @$core.pragma('dart2js:noInline')
  static ChangeSet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChangeSet>(create);
  static ChangeSet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class Node extends $pb.GeneratedMessage {
  factory Node({
    $fixnum.Int64? id,
    $core.Iterable<$core.int>? keys,
    $core.Iterable<$core.int>? vals,
    Info? info,
    $fixnum.Int64? lat,
    $fixnum.Int64? lon,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (keys != null) {
      $result.keys.addAll(keys);
    }
    if (vals != null) {
      $result.vals.addAll(vals);
    }
    if (info != null) {
      $result.info = info;
    }
    if (lat != null) {
      $result.lat = lat;
    }
    if (lon != null) {
      $result.lon = lon;
    }
    return $result;
  }
  Node._() : super();
  factory Node.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Node.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Node',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'keys', $pb.PbFieldType.KU3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'vals', $pb.PbFieldType.KU3)
    ..aOM<Info>(4, _omitFieldNames ? '' : 'info', subBuilder: Info.create)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.QS6,
        defaultOrMaker: $fixnum.Int64.ZERO);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Node clone() => Node()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Node copyWith(void Function(Node) updates) =>
      super.copyWith((message) => updates(message as Node)) as Node;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Node create() => Node._();
  Node createEmptyInstance() => create();
  static $pb.PbList<Node> createRepeated() => $pb.PbList<Node>();
  @$core.pragma('dart2js:noInline')
  static Node getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Node>(create);
  static Node? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Parallel arrays.
  @$pb.TagNumber(2)
  $core.List<$core.int> get keys => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get vals => $_getList(2);

  @$pb.TagNumber(4)
  Info get info => $_getN(3);
  @$pb.TagNumber(4)
  set info(Info v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => clearField(4);
  @$pb.TagNumber(4)
  Info ensureInfo() => $_ensure(3);

  @$pb.TagNumber(8)
  $fixnum.Int64 get lat => $_getI64(4);
  @$pb.TagNumber(8)
  set lat($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLat() => $_has(4);
  @$pb.TagNumber(8)
  void clearLat() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lon => $_getI64(5);
  @$pb.TagNumber(9)
  set lon($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasLon() => $_has(5);
  @$pb.TagNumber(9)
  void clearLon() => clearField(9);
}

class DenseNodes extends $pb.GeneratedMessage {
  factory DenseNodes({
    $core.Iterable<$fixnum.Int64>? id,
    DenseInfo? denseinfo,
    $core.Iterable<$fixnum.Int64>? lat,
    $core.Iterable<$fixnum.Int64>? lon,
    $core.Iterable<$core.int>? keysVals,
  }) {
    final $result = create();
    if (id != null) {
      $result.id.addAll(id);
    }
    if (denseinfo != null) {
      $result.denseinfo = denseinfo;
    }
    if (lat != null) {
      $result.lat.addAll(lat);
    }
    if (lon != null) {
      $result.lon.addAll(lon);
    }
    if (keysVals != null) {
      $result.keysVals.addAll(keysVals);
    }
    return $result;
  }
  DenseNodes._() : super();
  factory DenseNodes.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DenseNodes.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DenseNodes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.KS6)
    ..aOM<DenseInfo>(5, _omitFieldNames ? '' : 'denseinfo',
        subBuilder: DenseInfo.create)
    ..p<$fixnum.Int64>(8, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.KS6)
    ..p<$core.int>(10, _omitFieldNames ? '' : 'keysVals', $pb.PbFieldType.K3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DenseNodes clone() => DenseNodes()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DenseNodes copyWith(void Function(DenseNodes) updates) =>
      super.copyWith((message) => updates(message as DenseNodes)) as DenseNodes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DenseNodes create() => DenseNodes._();
  DenseNodes createEmptyInstance() => create();
  static $pb.PbList<DenseNodes> createRepeated() => $pb.PbList<DenseNodes>();
  @$core.pragma('dart2js:noInline')
  static DenseNodes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DenseNodes>(create);
  static DenseNodes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get id => $_getList(0);

  @$pb.TagNumber(5)
  DenseInfo get denseinfo => $_getN(1);
  @$pb.TagNumber(5)
  set denseinfo(DenseInfo v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDenseinfo() => $_has(1);
  @$pb.TagNumber(5)
  void clearDenseinfo() => clearField(5);
  @$pb.TagNumber(5)
  DenseInfo ensureDenseinfo() => $_ensure(1);

  @$pb.TagNumber(8)
  $core.List<$fixnum.Int64> get lat => $_getList(2);

  @$pb.TagNumber(9)
  $core.List<$fixnum.Int64> get lon => $_getList(3);

  /// Special packing of keys and vals into one array. May be empty if all nodes in this block are tagless.
  @$pb.TagNumber(10)
  $core.List<$core.int> get keysVals => $_getList(4);
}

class Way extends $pb.GeneratedMessage {
  factory Way({
    $fixnum.Int64? id,
    $core.Iterable<$core.int>? keys,
    $core.Iterable<$core.int>? vals,
    Info? info,
    $core.Iterable<$fixnum.Int64>? refs,
    $core.Iterable<$fixnum.Int64>? lat,
    $core.Iterable<$fixnum.Int64>? lon,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (keys != null) {
      $result.keys.addAll(keys);
    }
    if (vals != null) {
      $result.vals.addAll(vals);
    }
    if (info != null) {
      $result.info = info;
    }
    if (refs != null) {
      $result.refs.addAll(refs);
    }
    if (lat != null) {
      $result.lat.addAll(lat);
    }
    if (lon != null) {
      $result.lon.addAll(lon);
    }
    return $result;
  }
  Way._() : super();
  factory Way.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Way.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Way',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.Q6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'keys', $pb.PbFieldType.KU3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'vals', $pb.PbFieldType.KU3)
    ..aOM<Info>(4, _omitFieldNames ? '' : 'info', subBuilder: Info.create)
    ..p<$fixnum.Int64>(8, _omitFieldNames ? '' : 'refs', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(9, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.KS6)
    ..p<$fixnum.Int64>(10, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.KS6);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Way clone() => Way()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Way copyWith(void Function(Way) updates) =>
      super.copyWith((message) => updates(message as Way)) as Way;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Way create() => Way._();
  Way createEmptyInstance() => create();
  static $pb.PbList<Way> createRepeated() => $pb.PbList<Way>();
  @$core.pragma('dart2js:noInline')
  static Way getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Way>(create);
  static Way? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Parallel arrays.
  @$pb.TagNumber(2)
  $core.List<$core.int> get keys => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get vals => $_getList(2);

  @$pb.TagNumber(4)
  Info get info => $_getN(3);
  @$pb.TagNumber(4)
  set info(Info v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => clearField(4);
  @$pb.TagNumber(4)
  Info ensureInfo() => $_ensure(3);

  @$pb.TagNumber(8)
  $core.List<$fixnum.Int64> get refs => $_getList(4);

  ///  The following two fields are optional. They are only used in a special
  ///  format where node locations are also added to the ways. This makes the
  ///  files larger, but allows creating way geometries directly.
  ///
  ///  If this is used, you MUST set the optional_features tag "LocationsOnWays"
  ///  and the number of values in refs, lat, and lon MUST be the same.
  @$pb.TagNumber(9)
  $core.List<$fixnum.Int64> get lat => $_getList(5);

  @$pb.TagNumber(10)
  $core.List<$fixnum.Int64> get lon => $_getList(6);
}

class Relation extends $pb.GeneratedMessage {
  factory Relation({
    $fixnum.Int64? id,
    $core.Iterable<$core.int>? keys,
    $core.Iterable<$core.int>? vals,
    Info? info,
    $core.Iterable<$core.int>? rolesSid,
    $core.Iterable<$fixnum.Int64>? memids,
    $core.Iterable<Relation_MemberType>? types,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (keys != null) {
      $result.keys.addAll(keys);
    }
    if (vals != null) {
      $result.vals.addAll(vals);
    }
    if (info != null) {
      $result.info = info;
    }
    if (rolesSid != null) {
      $result.rolesSid.addAll(rolesSid);
    }
    if (memids != null) {
      $result.memids.addAll(memids);
    }
    if (types != null) {
      $result.types.addAll(types);
    }
    return $result;
  }
  Relation._() : super();
  factory Relation.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Relation.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Relation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'OSMPBF'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.Q6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'keys', $pb.PbFieldType.KU3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'vals', $pb.PbFieldType.KU3)
    ..aOM<Info>(4, _omitFieldNames ? '' : 'info', subBuilder: Info.create)
    ..p<$core.int>(8, _omitFieldNames ? '' : 'rolesSid', $pb.PbFieldType.K3)
    ..p<$fixnum.Int64>(9, _omitFieldNames ? '' : 'memids', $pb.PbFieldType.KS6)
    ..pc<Relation_MemberType>(
        10, _omitFieldNames ? '' : 'types', $pb.PbFieldType.KE,
        valueOf: Relation_MemberType.valueOf,
        enumValues: Relation_MemberType.values,
        defaultEnumValue: Relation_MemberType.NODE);

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Relation clone() => Relation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Relation copyWith(void Function(Relation) updates) =>
      super.copyWith((message) => updates(message as Relation)) as Relation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Relation create() => Relation._();
  Relation createEmptyInstance() => create();
  static $pb.PbList<Relation> createRepeated() => $pb.PbList<Relation>();
  @$core.pragma('dart2js:noInline')
  static Relation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Relation>(create);
  static Relation? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Parallel arrays.
  @$pb.TagNumber(2)
  $core.List<$core.int> get keys => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get vals => $_getList(2);

  @$pb.TagNumber(4)
  Info get info => $_getN(3);
  @$pb.TagNumber(4)
  set info(Info v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => clearField(4);
  @$pb.TagNumber(4)
  Info ensureInfo() => $_ensure(3);

  /// Parallel arrays
  @$pb.TagNumber(8)
  $core.List<$core.int> get rolesSid => $_getList(4);

  @$pb.TagNumber(9)
  $core.List<$fixnum.Int64> get memids => $_getList(5);

  @$pb.TagNumber(10)
  $core.List<Relation_MemberType> get types => $_getList(6);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
