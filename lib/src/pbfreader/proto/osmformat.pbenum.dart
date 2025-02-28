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

import 'package:protobuf/protobuf.dart' as $pb;

class Relation_MemberType extends $pb.ProtobufEnum {
  static const Relation_MemberType NODE =
      Relation_MemberType._(0, _omitEnumNames ? '' : 'NODE');
  static const Relation_MemberType WAY =
      Relation_MemberType._(1, _omitEnumNames ? '' : 'WAY');
  static const Relation_MemberType RELATION =
      Relation_MemberType._(2, _omitEnumNames ? '' : 'RELATION');

  static const $core.List<Relation_MemberType> values = <Relation_MemberType>[
    NODE,
    WAY,
    RELATION,
  ];

  static final $core.Map<$core.int, Relation_MemberType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Relation_MemberType? valueOf($core.int value) => _byValue[value];

  const Relation_MemberType._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
