import 'package:dart_rendertheme/rendertheme.dart';

/// The rendertheme for one specific zoomlevel
class RenderthemeZoomlevel {
  /// A list of rules which contains a list of rules which ...
  /// see defaultrender.xml how this is constructed.
  final List<Rule> rulesList; // NOPMD we need specific interface

  const RenderthemeZoomlevel({required this.rulesList});
}
