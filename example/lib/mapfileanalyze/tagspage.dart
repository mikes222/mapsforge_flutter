import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

class TagsPage extends StatefulWidget {
  final List<Tag> tags;

  const TagsPage({super.key, required this.tags});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

//////////////////////////////////////////////////////////////////////////////

class _TagsPageState extends State<TagsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.tags.mapIndexed((idx, element) => Text("$idx: ${element.key} = ${element.value}")).toList(),
        ),
      ),
    );
  }
}
