// file: lib/features/map/widgets/daily_interests_counter_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/notificatons/notifications_screen.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class DailyInterestsCounterWidget extends ConsumerWidget {
  const DailyInterestsCounterWidget({super.key});

  // Method to handle navigation to the notifications screen
  void _navigateToNotificationsScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new provider for the daily count
    final dailyCountAsyncValue = ref.watch(dailyInterestsCountProvider);

    return dailyCountAsyncValue.when(
      data: (count) {
        // Only display the widget if the count is greater than 0
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _navigateToNotificationsScreen(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const SizedBox.shrink(), // Don't show anything while loading
      error: (err, stack) => const SizedBox.shrink(), // Hide on error
    );
  }
}
