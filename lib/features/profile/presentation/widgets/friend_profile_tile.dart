// file: lib/features/profile/presentation/widgets/friend_profile_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class FriendProfileTile extends ConsumerWidget {
  final String friendUid;

  const FriendProfileTile({required this.friendUid, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendProfileAsyncValue = ref.watch(userProfileProvider(friendUid));
    final colorScheme = Theme.of(context).colorScheme;

    return friendProfileAsyncValue.when(
      data: (userProfile) {
        if (userProfile == null) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                userProfile.profileImageUrl != null &&
                        userProfile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(userProfile.profileImageUrl!)
                    : null,
            backgroundColor: colorScheme.surfaceVariant,
            child:
                userProfile.profileImageUrl == null ||
                        userProfile.profileImageUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
          ),
          title: Text(userProfile.name ?? 'Friend'),
          subtitle: Text(userProfile.shortBio ?? 'No bio available'),
          trailing: IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            color: colorScheme.primary,
            onPressed: () {
              // TODO: This will be the navigation to the chat screen
              debugPrint('Chat button pressed for ${userProfile.name}');
            },
          ),
          onTap: () {
            // Navigate to the user's profile when the tile is tapped
            context.push('/profile/$friendUid');
          },
        );
      },
      loading:
          () => const ListTile(
            leading: CircleAvatar(),
            title: Text('Loading...'),
          ),
      error:
          (e, st) => const ListTile(
            leading: CircleAvatar(),
            title: Text('Error loading user'),
          ),
    );
  }
}
