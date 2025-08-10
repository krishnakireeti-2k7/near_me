// file: lib/features/profile/presentation/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/map/widgets/interests_section.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:timeago/timeago.dart' as timeago;

// Import the essential reusable widget
import 'package:near_me/widgets/profile_info_card.dart';

// ✅ NEW IMPORTS for Friendship Feature
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository.dart';

class ViewProfileScreen extends ConsumerWidget {
  final String userId;
  final bool isCurrentUser;

  const ViewProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final theme = Theme.of(context);

    // ✅ NEW: Watch the friendship status
    final friendshipStatusAsync = ref.watch(
      friendshipStatusStreamProvider(userId),
    );
    final currentUserProfileAsync = ref.watch(currentUserProfileStreamProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isCurrentUser ? 'My Profile' : 'User Profile'),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            ),
            body: const Center(child: Text('Profile not found.')),
          );
        }

        // Calculation for lastActiveText (will still be performed for other users)
        String lastActiveText = "Never active";
        Color lastActiveColor = Colors.grey;
        if (profile.lastActive != null) {
          final DateTime lastActiveDateTime = profile.lastActive!.toDate();
          lastActiveText = 'Last active: ${timeago.format(lastActiveDateTime)}';
          if (DateTime.now().difference(lastActiveDateTime).inMinutes <= 5) {
            lastActiveColor = Colors.green;
          }
        }

        // Determine if there's any content for the main details card
        final bool hasBio =
            profile.shortBio != null && profile.shortBio!.isNotEmpty;
        final bool hasTags = profile.tags != null && profile.tags!.isNotEmpty;
        final bool hasSocial =
            (profile.socialHandles['instagram'] ?? '').isNotEmpty ||
            (profile.socialHandles['twitter'] ?? '').isNotEmpty;
        final bool hasDetailsContent = hasBio || hasTags || hasSocial;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isCurrentUser ? 'My Profile' : profile.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            leading:
                isCurrentUser
                    ? null
                    : IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            actions: [
              if (isCurrentUser) // Enable edit button for current user
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 28),
                  color: theme.colorScheme.primary,
                  onPressed: () {
                    context.push('/edit-profile/${profile.uid}');
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header Section (as a distinct card-like container)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            profile.profileImageUrl.isNotEmpty
                                ? NetworkImage(profile.profileImageUrl)
                                : null,
                        child:
                            profile.profileImageUrl.isEmpty
                                ? Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: 60,
                                )
                                : null,
                        backgroundColor: Colors.grey[100],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        profile.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      if (!isCurrentUser)
                        Text(
                          lastActiveText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: lastActiveColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        Text(
                          'Your Profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      // ✅ UPDATED: Add the friendship button below the profile info
                      if (!isCurrentUser &&
                          currentUserProfileAsync.value != null) ...[
                        const SizedBox(height: 24),
                        friendshipStatusAsync.when(
                          data: (friendship) {
                            final friendshipRepository = ref.read(
                              friendshipRepositoryProvider,
                            );
                            final currentUserProfile =
                                currentUserProfileAsync.value;
                            final currentUserId = currentUserProfile?.uid;
                            final currentUserName =
                                currentUserProfile?.name ?? '';

                            // The user is already a friend
                            if (friendship != null &&
                                friendship.status ==
                                    FriendshipStatus.accepted) {
                              return FilledButton.tonal(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text('Unfriend'),
                                          content: Text(
                                            'Are you sure you want to unfriend ${profile.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(ctx).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () async {
                                                if (currentUserId != null) {
                                                  await friendshipRepository
                                                      .unfriend(
                                                        user1Id: currentUserId,
                                                        user2Id: userId,
                                                      );
                                                  Navigator.of(ctx).pop();
                                                  showFloatingSnackBar(
                                                    context,
                                                    'You have unfriended ${profile.name}.',
                                                  );
                                                }
                                              },
                                              child: const Text('Unfriend'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                child: const Text('Friends'),
                              );
                            }

                            // A request is pending
                            if (friendship != null &&
                                friendship.status == FriendshipStatus.pending) {
                              if (friendship.senderId == currentUserId) {
                                // Use friendship.senderId here
                                return FilledButton.tonal(
                                  onPressed: null,
                                  child: const Text('Request Sent'),
                                );
                              } else {
                                return FilledButton(
                                  onPressed: () async {
                                    if (currentUserId != null) {
                                      await friendshipRepository
                                          .acceptFriendRequest(
                                            friendshipId: friendship.id,
                                            currentUserId: currentUserId,
                                            otherUserId: userId,
                                            currentUserName:
                                                currentUserName, // ✅ FIX: Pass the current user's name
                                          );
                                      showFloatingSnackBar(
                                        context,
                                        'You are now friends with ${profile.name}!',
                                      );
                                    }
                                  },
                                  child: const Text('Accept Request'),
                                );
                              }
                            }

                            // No friendship exists, show "Befriend" button
                            return FilledButton(
                              onPressed: () async {
                                if (currentUserId != null) {
                                  await friendshipRepository.sendFriendRequest(
                                    senderId: currentUserId,
                                    senderName:
                                        currentUserName, // ✅ FIX: Pass the sender's name
                                    receiverId: userId,
                                  );
                                  showFloatingSnackBar(
                                    context,
                                    'Friend request sent to ${profile.name}.',
                                  );
                                }
                              },
                              child: const Text('Befriend'),
                            );
                          },
                          loading:
                              () => const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Main Content Card (Conditionally displayed if there's any detail)
                if (hasDetailsContent) ...[
                  const SizedBox(height: 24),
                  ProfileInfoCard(
                    title: 'About & Connections',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasBio) ...[
                          Text(
                            profile.shortBio!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                              height: 1.5,
                            ),
                          ),
                          if (hasTags || hasSocial) const SizedBox(height: 16),
                        ],
                        if (hasTags) ...[
                          Text(
                            'Interests',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InterestsSection(tags: profile.tags!),
                          if (hasSocial) const SizedBox(height: 16),
                        ],
                        if (hasSocial) ...[
                          Text(
                            'Social Media',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if ((profile.socialHandles['instagram'] ?? '')
                                  .isNotEmpty)
                                _buildSocialLink(
                                  context,
                                  'Instagram',
                                  '@${profile.socialHandles['instagram']}',
                                  Colors.purple,
                                  Icons.camera_alt,
                                ),
                              if ((profile.socialHandles['twitter'] ?? '')
                                  .isNotEmpty)
                                _buildSocialLink(
                                  context,
                                  'Twitter',
                                  '@${profile.socialHandles['twitter']}',
                                  Colors.blue,
                                  Icons.mail,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading:
          () => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, st) => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: Text('Error loading profile: $e')),
          ),
    );
  }

  Widget _buildSocialLink(
    BuildContext context,
    String platform,
    String handle,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opening $platform link for $handle (feature coming soon)!',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Text(
              handle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
