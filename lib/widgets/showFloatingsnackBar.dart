// file: lib/widgets/showFloatingsnackBar.dart

import 'package:flutter/material.dart';

// Define an enum for SnackBar position
enum SnackBarPosition { top, bottom } // <--- NEW ENUM

void showFloatingSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onActionPressed,
  IconData? leadingIcon,
  SnackBarPosition position =
      SnackBarPosition.bottom, // <--- NEW PARAMETER with default
}) {
  EdgeInsets margin;
  if (position == SnackBarPosition.top) {
    // Calculate margin for top, adjusting for the status bar (safe area)
    margin = EdgeInsets.only(
      top:
          MediaQuery.of(context).padding.top +
          20.0, // 20.0 from status bar bottom
      left: 20.0,
      right: 20.0,
    );
  } else {
    // Original bottom margin
    margin = const EdgeInsets.only(bottom: 80.0, left: 20.0, right: 20.0);
  }

  final SnackBar snackBar = SnackBar(
    content: Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: textColor),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(message, style: TextStyle(color: textColor))),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor:
        backgroundColor ?? Theme.of(context).colorScheme.inverseSurface,
    duration: duration,
    margin: margin, // <--- Use the dynamically determined margin
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

  // Hide any currently showing snackbar before showing a new one
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
