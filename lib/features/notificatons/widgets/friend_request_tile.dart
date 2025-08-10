// file: lib/features/notificatons/widgets/friend_request_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:go_router/go_router.dart';

class FriendRequestTile extends ConsumerWidget {
  final UserProfileModel profile;
  final FriendshipModel request;
  final VoidCallback onDismissed;

  const FriendRequestTile({
    required this.profile,
    required this.request,
    required this.onDismissed,
    super.key,
  });

  Future<void> _handleAccept(WidgetRef ref, BuildContext context) async {
    final friendshipRepository = ref.read(friendshipRepositoryProvider);
    final currentUserProfile =
        ref
            .read(currentUserProfileStreamProvider)
            .value; // ✅ NEW: Get current user profile
    final currentUserId = currentUserProfile?.uid;
    final currentUserName =
        currentUserProfile?.name ?? ''; // ✅ NEW: Get current user name

    if (currentUserId != null) {
      await friendshipRepository.acceptFriendRequest(
        friendshipId: request.id,
        currentUserId: currentUserId,
        otherUserId: profile.uid,
        currentUserName:
            currentUserName, // ✅ FIX: Pass the new required parameter
      );
      if (context.mounted) {
        showFloatingSnackBar(
          context,
          'You are now friends with ${profile.name}!',
        );
      }
    }
  }

  Future<void> _handleReject(WidgetRef ref, BuildContext context) async {
    final friendshipRepository = ref.read(friendshipRepositoryProvider);
    try {
      await friendshipRepository.deleteFriendRequest(request.id);
      onDismissed();
      if (context.mounted) {
        showFloatingSnackBar(
          context,
          'Friend request from ${profile.name} rejected.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFloatingSnackBar(
          context,
          'Failed to reject request: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/profile/${profile.uid}'),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(profile.profileImageUrl),
        ),
        title: Text(
          profile.name,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('wants to be friends.'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: () => _handleAccept(ref, context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _handleReject(ref, context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                child: const Text('Reject'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
