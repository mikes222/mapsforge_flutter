import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef void OnChange(int level);

/// Statefull Widget to display a level bar
/// requires a BehaviourSubject of type int for the current indoor level
/// requires a map of levels with an optional level code string
/// The map will be automatically ordered from high to low
class IndoorLevelBar extends StatefulWidget {
  final Map<int, String?> indoorLevels;
  final double width;
  final double itemHeight;
  final int maxVisibleItems;
  final Color fillColor;
  final Color activeColor;
  final double elevation;
  final BorderRadius borderRadius;
  final OnChange onChange;
  final int initialLevel;

  const IndoorLevelBar({
    Key? key,
    required this.indoorLevels,
    required this.onChange,
    this.width: 30,
    this.itemHeight: 45,
    this.maxVisibleItems: 5,
    this.fillColor: Colors.white,
    this.activeColor: Colors.blue,
    this.elevation: 2,
    this.borderRadius: const BorderRadius.all(Radius.circular(20)),
    this.initialLevel = 0,
  }) : super(key: key);

  @override
  IndoorLevelBarState createState() => IndoorLevelBarState();
}

/////////////////////////////////////////////////////////////////////////////

class IndoorLevelBarState extends State<IndoorLevelBar> {
  ScrollController? _scrollController;

  ValueNotifier<bool> _onTop = ValueNotifier<bool>(false);
  ValueNotifier<bool> _onBottom = ValueNotifier<bool>(false);

  late int _level;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
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
    // widget
    return Material(
      elevation: widget.elevation,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: widget.fillColor,
      child: LayoutBuilder(
          // will also be called on device orientation change
          builder: (context, constraints) {
        // get the total number of levels
        int totalIndoorLevels = widget.indoorLevels.length;
        // extract levels to list and sorts all levels from high to low (descending)
        List<int> indoorLevels = widget.indoorLevels.keys.toList();
        indoorLevels.sort((b, a) => a.compareTo(b));

        double maxHeight = min(
            constraints.maxHeight, widget.maxVisibleItems * widget.itemHeight);
        // calculate nearest multiple item height
        maxHeight = (maxHeight / widget.itemHeight).floor() * widget.itemHeight;
        // check if level bar will be scrollable
        bool isScrollable = maxHeight < totalIndoorLevels * widget.itemHeight;

        // if level bar will be scrollable
        if (isScrollable) {
          // calculate the scroll position so the selected element is visible at the bottom if possible
          // -3 because we need to shift the index by 1 and by 2 because of scroll buttons taking each the space of one item
          int itemIndex = indoorLevels.indexOf(_level);
          double selectedItemOffset = max(
              itemIndex * widget.itemHeight -
                  (maxHeight - 3 * widget.itemHeight),
              0);
          // create scroll controller if not existing and set item scroll offset
          _scrollController ??=
              ScrollController(initialScrollOffset: selectedItemOffset);
          // else
          //   _scrollController!.jumpTo(selectedItemOffset);

          // disable/enable scroll buttons accordingly
          _onTop.value = selectedItemOffset == 0;
          _onBottom.value = selectedItemOffset ==
              totalIndoorLevels * widget.itemHeight -
                  (maxHeight - 2 * widget.itemHeight);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            // set to nearest multiple item height
            maxHeight: maxHeight,
            maxWidth: widget.width,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Visibility(
                // toggle on if level bar will be scrollable
                visible: isScrollable,
                child: ValueListenableBuilder(
                  valueListenable: _onTop,
                  builder: (BuildContext context, bool onTop, Widget? child) {
                    return TextButton(
                      style: TextButton.styleFrom(
                        primary: Colors.black,
                        backgroundColor: Colors.transparent,
                        shape: const ContinuousRectangleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // make buttons same height as items
                        minimumSize: Size.fromHeight(widget.itemHeight),
                      ),
                      onPressed: onTop ? null : scrollLevelUp,
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
                    itemCount: totalIndoorLevels,
                    itemExtent: widget.itemHeight,
                    itemBuilder: (context, i) {
                      // get item indoor level from index
                      int itemIndoorLevel = indoorLevels[i];
                      // widget
                      return TextButton(
                        style: TextButton.styleFrom(
                          shape: const ContinuousRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: _level == itemIndoorLevel
                              ? widget.activeColor
                              : Colors.transparent,
                          primary: _level == itemIndoorLevel
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () {
                          // do nothing if already selected
                          if (_level != itemIndoorLevel) {
                            widget.onChange(itemIndoorLevel);
                            if (mounted)
                              setState(() {
                                _level = itemIndoorLevel;
                              });
                          }
                        },
                        child: Text(
                          // show level code if available
                          widget.indoorLevels[itemIndoorLevel] ??
                              itemIndoorLevel.toString(),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Visibility(
                // toggle on if level bar will be scrollable
                visible: isScrollable,
                child: ValueListenableBuilder(
                  valueListenable: _onBottom,
                  builder:
                      (BuildContext context, bool onBottom, Widget? child) {
                    return TextButton(
                      style: TextButton.styleFrom(
                        primary: Colors.black,
                        backgroundColor: Colors.transparent,
                        shape: const ContinuousRectangleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // make buttons same height as items
                        minimumSize: Size.fromHeight(widget.itemHeight),
                      ),
                      onPressed: onBottom ? null : scrollLevelDown,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _handleScrollChanges(notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
        if (_onTop.value == false) _onTop.value = true;
      } else if (_onTop.value == true) _onTop.value = false;

      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
        if (_onBottom.value == false) _onBottom.value = true;
      } else if (_onBottom.value == true) _onBottom.value = false;
    }
    // cancels notification bubbling
    return true;
  }

  void scrollLevelUp() {
    if (_scrollController == null) return;

    double itemHeight = widget.itemHeight;
    double nextPosition = _scrollController!.offset - itemHeight;
    double roundToNextItemPosition =
        (nextPosition / itemHeight).round() * itemHeight;
    _scrollController!.animateTo(
      roundToNextItemPosition,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }

  void scrollLevelDown() {
    if (_scrollController == null) return;

    double itemHeight = widget.itemHeight;
    double nextPosition = _scrollController!.offset + itemHeight;
    double roundToNextItemPosition =
        (nextPosition / itemHeight).round() * itemHeight;
    _scrollController!.animateTo(
      roundToNextItemPosition,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }
}
