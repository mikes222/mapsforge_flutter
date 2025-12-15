// This is a generated file - do not edit.
//
// Generated from lib/pbfproto/osmformat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

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

  static final $core.List<Relation_MemberType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Relation_MemberType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Relation_MemberType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
