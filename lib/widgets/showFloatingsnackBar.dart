// file: lib/widgets/showFloatingsnackBar.dart

import 'package:flutter/material.dart';

enum SnackBarPosition { top, bottom }

void showFloatingSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onActionPressed,
  IconData? leadingIcon,
  SnackBarPosition position = SnackBarPosition.bottom,
  bool isError = false, // <-- Add this new parameter
}) {
  EdgeInsets margin;
  if (position == SnackBarPosition.top) {
    margin = EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 20.0,
      left: 20.0,
      right: 20.0,
    );
  } else {
    margin = const EdgeInsets.only(bottom: 80.0, left: 20.0, right: 20.0);
  }

  // Determine background and text color based on the new isError parameter
  final effectiveBackgroundColor =
      isError
          ? Colors.red.shade700
          : (backgroundColor ?? Theme.of(context).colorScheme.inverseSurface);
  final effectiveTextColor = isError ? Colors.white : textColor;

  final SnackBar snackBar = SnackBar(
    content: Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: effectiveTextColor),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(message, style: TextStyle(color: effectiveTextColor)),
        ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: effectiveBackgroundColor,
    duration: duration,
    margin: margin,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    elevation: 6.0,
    action:
        (actionLabel != null && onActionPressed != null)
            ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed,
              textColor: Colors.amberAccent,
            )
            : null,
  );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
