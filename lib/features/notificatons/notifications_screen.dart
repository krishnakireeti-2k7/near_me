// file: lib/features/notificatons/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:near_me/features/notificatons/widgets/friend_request_tile.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInterestsAsync = ref.watch(allInterestsProvider);
    final friendRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // We watch the providers individually and nest the `when` blocks.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
      ),
      backgroundColor: colorScheme.background,
      body: allInterestsAsync.when(
        data: (interests) {
          // Now we handle the second provider inside the first's `when` block.
          return friendRequestsAsync.when(
            data: (friendRequests) {
              final allNotifications = [
                ...interests.map(
                  (i) => {
                    'type': 'interest',
                    'data': i,
                    'timestamp': (i['timestamp'] as Timestamp).toDate(),
                  },
                ),
                ...friendRequests.map(
                  (r) => {
                    'type': 'friendRequest',
                    'data': r,
                    'timestamp': r.timestamp.toDate(),
                  },
                ),
              ];

              // Explicitly cast the values to `DateTime` before comparing.
              allNotifications.sort(
                (a, b) => (b['timestamp'] as DateTime).compareTo(
                  a['timestamp'] as DateTime,
                ),
              );

              if (allNotifications.isEmpty) {
                return Center(
                  child: Text(
                    'You have no new notifications.',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: allNotifications.length,
                itemBuilder: (context, index) {
                  final notification = allNotifications[index];
                  final type = notification['type'];

                  if (type == 'friendRequest') {
                    final request = notification['data'] as FriendshipModel;
                    return _buildFriendRequestTile(context, ref, request);
                  } else if (type == 'interest') {
                    final interest =
                        notification['data'] as Map<String, dynamic>;
                    return _buildInterestTile(context, ref, interest);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) =>
                    Center(child: Text('Error loading friend requests: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text('Error loading interests: $err')),
      ),
    );
  }

  Widget _buildFriendRequestTile(
    BuildContext context,
    WidgetRef ref,
    FriendshipModel request,
  ) {
    final senderProfileAsync = ref.watch(userProfileProvider(request.senderId));
    final friendshipRepository = ref.read(friendshipRepositoryProvider);

    return senderProfileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Dismissible(
          key: ValueKey(request.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await friendshipRepository.deleteFriendRequest(request.id);
            if (context.mounted) {
              showFloatingSnackBar(context, 'Friend request dismissed.');
            }
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: FriendRequestTile(
            profile: profile,
            request: request,
            onDismissed: () {},
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildInterestTile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> interest,
  ) {
    final fromUserId = interest['fromUserId'] as String;
    final timestamp = (interest['timestamp'] as Timestamp).toDate();
    final documentId = interest['documentId'] as String;

    final interestDeletionCallback = ref.read(interestDeletionProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
          await interestDeletionCallback(documentId);
          if (context.mounted) {
            showFloatingSnackBar(context, 'Interest dismissed');
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
      child: InterestTile(fromUserId: fromUserId, timestamp: timestamp),
    );
  }
}

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
