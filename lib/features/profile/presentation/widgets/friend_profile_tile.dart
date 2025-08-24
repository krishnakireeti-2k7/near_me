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

        return InkWell(
          // ✅ Use InkWell for a clean tap effect
          onTap: () {
            context.pushNamed(
              'chat',
              pathParameters: {'otherUserId': friendUid},
              queryParameters: {'name': userProfile.name ?? 'Friend'},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                16,
              ), // ✅ Increased border radius for a softer look
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 8,
            ), // ✅ Adjusted vertical margin
            child: Padding(
              padding: const EdgeInsets.all(16.0), // ✅ Generous padding
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30, // ✅ Larger avatar
                    backgroundImage:
                        userProfile.profileImageUrl != null &&
                                userProfile.profileImageUrl!.isNotEmpty
                            ? NetworkImage(userProfile.profileImageUrl!)
                            : null,
                    backgroundColor: colorScheme.surfaceVariant,
                    child:
                        userProfile.profileImageUrl == null ||
                                userProfile.profileImageUrl!.isEmpty
                            ? Icon(
                              Icons.person,
                              color: colorScheme.onSurface,
                              size: 30,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name ?? 'Friend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile.shortBio ?? 'No bio available',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2, // ✅ Allow for a slightly longer bio
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Error loading user')),
    );
  }
}
