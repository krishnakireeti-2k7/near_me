// file: lib/widgets/themed_switch_list_tile.dart

import 'package:flutter/material.dart';

class ThemedSwitchListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const ThemedSwitchListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFff6b6b),
        inactiveThumbColor: Colors.grey.shade300,
        inactiveTrackColor: Colors.grey.shade700,
        contentPadding: EdgeInsets.zero,
        secondary: icon != null ? Icon(icon, color: Colors.black54) : null,
      ),
    );
  }
}
