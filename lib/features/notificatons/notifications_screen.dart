// file: lib/features/profile/presentation/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInterests = ref.watch(allInterestsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
      ),
      backgroundColor: colorScheme.background,
      body: allInterests.when(
        data: (interests) {
          if (interests.isEmpty) {
            return Center(
              child: Text(
                'No one has shown interest yet 😢\nGet out there and meet new people!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onBackground.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: interests.length + 1, // +1 for the catchy header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'You’ve been catching eyes lately 😉',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }

              final interest = interests[index - 1];
              final fromUserId = interest['fromUserId'] ?? 'Unknown';
              final timestamp = interest['timestamp']?.toDate();

              return NotificationCard(
                fromUserId: fromUserId,
                timestamp: timestamp,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Text(
                'Error: ${err.toString()}',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
      ),
    );
  }
}

class NotificationCard extends ConsumerWidget {
  final String fromUserId;
  final DateTime? timestamp;

  const NotificationCard({
    required this.fromUserId,
    required this.timestamp,
    super.key,
  });

  String _formatTimestamp(DateTime? time) {
    if (time == null) return 'some time ago';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(fromUserId));
    final colorScheme = Theme.of(context).colorScheme;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final formattedTime = _formatTimestamp(timestamp);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surfaceVariant.withOpacity(0.4),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      profile.profileImageUrl?.isNotEmpty == true
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                  child:
                      profile.profileImageUrl?.isEmpty != false
                          ? Icon(
                            Icons.person,
                            size: 28,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          )
                          : null,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '🔥 ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.name} showed interest • $formattedTime',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => context.push('/profile/${profile.uid}'),
                  icon: const Icon(Icons.person_search_outlined, size: 18),
                  label: const Text('Check them out'),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) =>
              Center(child: Text('Error loading profile: ${e.toString()}')),
    );
  }
}
