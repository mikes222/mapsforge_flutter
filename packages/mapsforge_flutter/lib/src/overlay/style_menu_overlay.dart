import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/overlay/style_menu_bar.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

class StyleMenuOverlay extends StatefulWidget {
  final StyleMenu styleMenu;

  /// Callback invoked when a layer (style) is selected.
  ///
  /// The host application is responsible for applying the selection (e.g.
  /// reloading theme with selected style / categories / overlays).
  final void Function(String layerId) onChange;

  /// Optional desired language for layer names.
  final String? lang;

  /// Padding from the top-left corner.
  final double padding;

  /// Optional initial selected layer id.
  final String? initialLayerId;

  StyleMenuOverlay({
    required this.styleMenu,
    required this.onChange,
    this.lang,
    this.padding = 15,
    this.initialLayerId,
  });

  @override
  State<StatefulWidget> createState() {
    return _StyleMenuOverlayState();
  }
}

class _StyleMenuOverlayState extends State<StyleMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

  @override
  void initState() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeAnimationController, curve: Curves.ease);

    super.initState();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _fadeAnimationController.forward();

    return Positioned(
      top: widget.padding,
      left: widget.padding,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: StyleMenuBar(
          styleMenu: widget.styleMenu,
          onChange: widget.onChange,
          lang: widget.lang,
          initialLayerId: widget.initialLayerId,
        ),
      ),
    );
  }
}
