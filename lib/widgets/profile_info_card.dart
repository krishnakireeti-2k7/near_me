// file: lib/widgets/profile_info_card.dart

import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ProfileInfoCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity, // Take full width
      padding: const EdgeInsets.all(20), // Generous padding
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(
              0,
              0,
              0,
              0.08,
            ), // Consistent subtle shadow
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: Colors.grey,
          ), // Subtle divider
          const SizedBox(height: 8),
          child, // The actual content (bio, interests, social links)
        ],
      ),
    );
  }
}
