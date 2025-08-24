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
        if (userProfile == null) return const SizedBox.shrink();

        final avatar = CircleAvatar(
          radius: 30,
          backgroundImage:
              userProfile.profileImageUrl != null &&
                      userProfile.profileImageUrl!.isNotEmpty
                  ? NetworkImage(userProfile.profileImageUrl!)
                  : null,
          backgroundColor: colorScheme.surfaceVariant,
          child:
              (userProfile.profileImageUrl == null ||
                      userProfile.profileImageUrl!.isEmpty)
                  ? Icon(Icons.person, color: colorScheme.onSurface, size: 26)
                  : null,
        );

        // ✅ Directory style (ID card style)
        return InkWell(
          onTap: () {
            context.pushNamed(
              'chat',
              pathParameters: {'otherUserId': friendUid},
              queryParameters: {'name': userProfile.name ?? 'Friend'},
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.name ?? 'Friend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userProfile.shortBio ?? 'No bio available',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurface),
              ],
            ),
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error: (e, st) => const Center(child: Text('Error loading user')),
    );
  }
}
