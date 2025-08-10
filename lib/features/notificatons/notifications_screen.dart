// file: lib/features/notificatons/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:near_me/features/notificatons/widgets/friend_request_tile.dart';
import 'package:near_me/features/profile/repository/friendship_repository.dart';
// The InterestTile you have is defined in this same file, so no external import needed.

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We'll watch a simplified stream that returns a List<Map<String, dynamic>>
    // to match your `InterestTile`'s data structure.
    final allInterests = ref.watch(allInterestsProvider);
    final friendRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
      ),
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FRIEND REQUESTS SECTION
              friendRequestsAsync.when(
                data: (requests) {
                  if (requests.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friend Requests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          final senderProfileAsync = ref.watch(
                            userProfileProvider(request.senderId),
                          );

                          return senderProfileAsync.when(
                            data: (profile) {
                              if (profile == null) {
                                return const SizedBox.shrink();
                              }
                              return Dismissible(
                                key: ValueKey(request.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  final friendshipRepository = ref.read(
                                    friendshipRepositoryProvider,
                                  );
                                  await friendshipRepository
                                      .deleteFriendRequest(request.id);
                                  if (context.mounted) {
                                    showFloatingSnackBar(
                                      context,
                                      'Friend request dismissed.',
                                    );
                                  }
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: FriendRequestTile(
                                  profile: profile,
                                  request: request,
                                  onDismissed: () {},
                                ),
                              );
                            },
                            loading:
                                () => const SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            error: (err, stack) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) =>
                        const Text('Error loading friend requests.'),
              ),

              // 2. INTERESTS SECTION
              Text(
                'Interests',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // ✅ FIX: The data is a QuerySnapshot, so we need to map it correctly.
              allInterests.when(
                data: (interests) {
                  // The data is now a list of maps, not a QuerySnapshot
                  if (interests.isEmpty) {
                    return Center(
                      child: Text(
                        'No one has shown interest yet 😢',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: interests.length,
                    itemBuilder: (context, index) {
                      final interest = interests[index];
                      final fromUserId = interest['fromUserId'] ?? 'Unknown';
                      final timestamp = interest['timestamp']?.toDate();
                      final documentId = interest['documentId'] as String?;

                      if (documentId == null) {
                        return const SizedBox.shrink();
                      }

                      return Dismissible(
                        key: ValueKey(documentId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          try {
                            // ✅ FIX: Use the interestDeletionProvider to remove the interest.
                            await ref.read(interestDeletionProvider)(
                              documentId,
                            );
                            if (context.mounted) {
                              showFloatingSnackBar(
                                context,
                                'Interest dismissed',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showFloatingSnackBar(
                                context,
                                'Failed to dismiss interest: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: InterestTile(
                          // This is your original InterestTile from this file.
                          fromUserId: fromUserId,
                          timestamp: timestamp,
                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Restored your original InterestTile widget from this same file.
class InterestTile extends ConsumerWidget {
  final String fromUserId;
  final DateTime? timestamp;

  const InterestTile({
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
                      profile.profileImageUrl.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl)
                          : null,
                  child:
                      profile.profileImageUrl.isEmpty
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
