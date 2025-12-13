import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

typedef OnStyleChange = void Function(StyleMenuLayer layer);

/// Stateful widget to display a vertical style menu bar.
///
/// This is intentionally similar in interaction and appearance to [IndoorLevelBar],
/// but it shows the user-visible layers of a Mapsforge render theme stylemenu.
class StyleMenuBar extends StatefulWidget {
  final StyleMenu styleMenu;
  final double width;
  final double itemHeight;
  final int maxVisibleItems;
  final Color fillColor;
  final Color activeColor;
  final double elevation;
  final BorderRadius borderRadius;
  final OnStyleChange onChange;

  /// Optional initial layer id.
  ///
  /// If not provided, [StyleMenu.defaultValue] is used, otherwise the first
  /// selectable layer.
  final String? initialLayerId;

  /// Optional desired language for layer names.
  ///
  /// If not set, [StyleMenu.defaultLang] is used, otherwise the first translation.
  final String? lang;

  const StyleMenuBar({
    super.key,
    required this.styleMenu,
    required this.onChange,
    this.width = 140,
    this.itemHeight = 45,
    this.maxVisibleItems = 5,
    this.fillColor = Colors.white,
    this.activeColor = Colors.blue,
    this.elevation = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.initialLayerId,
    this.lang,
  });

  @override
  State<StyleMenuBar> createState() => StyleMenuBarState();
}

class StyleMenuBarState extends State<StyleMenuBar> {
  ScrollController? _scrollController;

  final ValueNotifier<bool> _onTop = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _onBottom = ValueNotifier<bool>(false);

  late String _layerId;

  @override
  void initState() {
    super.initState();

    final layers = _selectableLayers(widget.styleMenu);
    final fallback = layers.isNotEmpty ? layers.first.id : '';

    _layerId = widget.initialLayerId ?? widget.styleMenu.defaultValue ?? fallback;
  }

  @override
  void didUpdateWidget(covariant StyleMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.styleMenu != widget.styleMenu) {
      final layers = _selectableLayers(widget.styleMenu);
      final fallback = layers.isNotEmpty ? layers.first.id : '';
      final newDefault = widget.initialLayerId ?? widget.styleMenu.defaultValue ?? fallback;

      if (_layerId.isEmpty || widget.styleMenu.layerById(_layerId) == null) {
        _layerId = newDefault;
      }

      _scrollController?.dispose();
      _scrollController = null;
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _onTop.dispose();
    _onBottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: widget.elevation,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: widget.fillColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layers = _selectableLayers(widget.styleMenu);
          final totalLayers = layers.length;

          double maxHeight = min(constraints.maxHeight, widget.maxVisibleItems * widget.itemHeight);
          maxHeight = (maxHeight / widget.itemHeight).floor() * widget.itemHeight;

          final bool isScrollable = maxHeight < totalLayers * widget.itemHeight;

          if (isScrollable && totalLayers > 0) {
            final int itemIndex = layers.indexWhere((l) => l.id == _layerId);
            final int safeIndex = itemIndex < 0 ? 0 : itemIndex;

            final double selectedItemOffset = max<double>(safeIndex * widget.itemHeight - (maxHeight - 3 * widget.itemHeight), 0.0);

            _scrollController ??= ScrollController(initialScrollOffset: selectedItemOffset);

            _onTop.value = selectedItemOffset == 0;
            _onBottom.value = selectedItemOffset == (totalLayers * widget.itemHeight - (maxHeight - 2 * widget.itemHeight));
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: widget.width),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Visibility(
                  visible: isScrollable,
                  child: ValueListenableBuilder(
                    valueListenable: _onTop,
                    builder: (BuildContext context, bool onTop, Widget? child) {
                      return TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.transparent,
                          shape: const ContinuousRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.fromHeight(widget.itemHeight),
                        ),
                        onPressed: onTop ? null : _scrollUp,
                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                      );
                    },
                  ),
                ),
                Flexible(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollChanges,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalLayers,
                      itemExtent: widget.itemHeight,
                      itemBuilder: (context, i) {
                        final layer = layers[i];
                        final isActive = _layerId == layer.id;

                        return TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isActive ? Colors.white : Colors.black,
                            shape: const ContinuousRectangleBorder(),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isActive ? widget.activeColor : Colors.transparent,
                          ),
                          onPressed: () {
                            if (_layerId != layer.id) {
                              widget.onChange(layer);
                              if (mounted) {
                                setState(() {
                                  _layerId = layer.id;
                                });
                              }
                            }
                          },
                          child: Text(_layerLabel(layer), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2),
                        );
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: isScrollable,
                  child: ValueListenableBuilder(
                    valueListenable: _onBottom,
                    builder: (BuildContext context, bool onBottom, Widget? child) {
                      return TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.transparent,
                          shape: const ContinuousRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.fromHeight(widget.itemHeight),
                        ),
                        onPressed: onBottom ? null : _scrollDown,
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<StyleMenuLayer> _selectableLayers(StyleMenu menu) {
    final visibleLayers = menu.layers.where((l) => l.visible == true).toList(growable: false);
    if (visibleLayers.isNotEmpty) return visibleLayers;
    return menu.layers;
  }

  String _layerLabel(StyleMenuLayer layer) {
    final requestedLang = widget.lang;
    final fallbackLang = widget.styleMenu.defaultLang;

    if (requestedLang != null && requestedLang.isNotEmpty) {
      return layer.nameForLang(requestedLang, fallbackLang: fallbackLang) ?? layer.id;
    }

    if (fallbackLang != null && fallbackLang.isNotEmpty) {
      return layer.nameForLang(fallbackLang) ?? layer.id;
    }

    return layer.nameForLang('') ?? layer.id;
  }

  bool _handleScrollChanges(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
        if (_onTop.value == false) _onTop.value = true;
      } else if (_onTop.value == true) {
        _onTop.value = false;
      }

      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
        if (_onBottom.value == false) _onBottom.value = true;
      } else if (_onBottom.value == true) {
        _onBottom.value = false;
      }
    }
    return true;
  }

  void _scrollUp() {
    if (_scrollController == null) return;

    final itemHeight = widget.itemHeight;
    final nextPosition = _scrollController!.offset - itemHeight;
    final roundToNextItemPosition = (nextPosition / itemHeight).round() * itemHeight;

    _scrollController!.animateTo(roundToNextItemPosition, duration: const Duration(milliseconds: 200), curve: Curves.fastOutSlowIn);
  }

  void _scrollDown() {
    if (_scrollController == null) return;

    final itemHeight = widget.itemHeight;
    final nextPosition = _scrollController!.offset + itemHeight;
    final roundToNextItemPosition = (nextPosition / itemHeight).round() * itemHeight;

    _scrollController!.animateTo(roundToNextItemPosition, duration: const Duration(milliseconds: 200), curve: Curves.fastOutSlowIn);
  }
}
