import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabeltextCustom extends StatelessWidget {
  final String label;

  final String? value;

  final int maxLines;

  final double? fontSize;

  final Color? fontColor;

  LabeltextCustom({required this.label, this.value, this.maxLines = 1, this.fontSize, this.fontColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label + (label.isNotEmpty ? ": " : ""),
          style: TextStyle(fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize, fontStyle: FontStyle.italic, color: Colors.blueGrey),
        ),
        buildText(context),
      ],
    );
  }

  Widget buildText(BuildContext context) {
    return maxLines > 1
        ? Flexible(
            child: buildGesture(
              Text(
                value ?? "",
                overflow: TextOverflow.ellipsis,
                maxLines: maxLines,
                style: TextStyle(
                  fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize,
                  color: fontColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          )
        : buildGesture(
            Text(
              value ?? "",
              style: TextStyle(
                fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize,
                color: fontColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
  }

  Widget buildGesture(Widget child) {
    return GestureDetector(
      child: child,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: value ?? ""));
        //        if (scaffoldKey != null)
        //          new UiDefault().showMessage(scaffoldKey, "Copied to Clipboard");
      },
    );
  }
}
