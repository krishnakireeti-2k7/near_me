// file: lib/widgets/showFloatingsnackBar.dart

import 'package:flutter/material.dart';

void showFloatingSnackBar(
  BuildContext context,
  String message, {
  Color?
  backgroundColor, // Now optional, defaults to SnackBar's default if null
  Color textColor = Colors.white, // New: Allows custom text color
  Duration duration = const Duration(
    seconds: 3,
  ), // Slightly increased default duration
  String? actionLabel,
  VoidCallback? onActionPressed,
  IconData? leadingIcon, // New: Optional leading icon
}) {
  final SnackBar snackBar = SnackBar(
    content: Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: textColor),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: textColor), // Apply custom text color
          ),
        ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor:
        backgroundColor ??
        Theme.of(
          context,
        ).colorScheme.inverseSurface, // Use provided color, or theme default
    duration: duration,
    margin: const EdgeInsets.only(
      bottom: 80.0,
      left: 20.0,
      right: 20.0,
    ), // Consistent margin
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0), // Rounded corners
    ),
    elevation: 6.0, // Adds a subtle shadow for a better floating effect
    action:
        (actionLabel != null && onActionPressed != null)
            ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed,
              textColor: Colors.amberAccent, // Color for the action button text
            )
            : null,
  );

  // Hide any currently showing snackbar before showing a new one
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
