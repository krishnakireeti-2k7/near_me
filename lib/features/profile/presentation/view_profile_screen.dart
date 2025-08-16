// file: lib/features/profile/presentation/view_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/widgets/profile_info_card.dart';
import 'package:near_me/features/map/widgets/interests_section.dart';
import 'package:timeago/timeago.dart' as timeago;

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

    final friendshipStatusAsync = ref.watch(
      friendshipStatusStreamProvider(userId),
    );
    final currentUserProfile = ref.watch(
      currentUserProfileProvider,
    ); // Changed to synchronous provider
    final friendsCount = currentUserProfile?.friends?.length ?? 0;
    final dailyInterestsCount = ref.watch(dailyInterestsCountProvider);
    final pendingFriendRequestsCount = ref.watch(
      pendingFriendRequestsCountProvider,
    );

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

        String lastActiveText = "Never active";
        Color lastActiveColor = theme.colorScheme.onSurface.withOpacity(0.5);
        if (profile.lastActive != null) {
          final DateTime lastActiveDateTime = profile.lastActive!.toDate();
          lastActiveText = 'Last active: ${timeago.format(lastActiveDateTime)}';
          if (DateTime.now().difference(lastActiveDateTime).inMinutes <= 5) {
            lastActiveColor = theme.colorScheme.tertiary;
          }
        }

        final bool hasBio = profile.shortBio.isNotEmpty;
        final bool hasTags = profile.tags.isNotEmpty;
        final bool hasSocial =
            (profile.socialHandles['instagram'] ?? '').isNotEmpty ||
            (profile.socialHandles['twitter'] ?? '').isNotEmpty;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/map');
                }
              },
            ),
            actions: [
              if (isCurrentUser)
                IconButton(
                  icon: Icon(
                    Icons.edit_note_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    context.push('/edit-profile/${profile.uid}');
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header
                Column(
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.4,
                                ),
                                size: 60,
                              )
                              : null,
                      backgroundColor: theme.cardColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCurrentUser ? 'Your Profile' : lastActiveText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isCurrentUser
                                ? theme.colorScheme.primary
                                : lastActiveColor,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action Buttons
                if (!isCurrentUser && currentUserProfile != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: friendshipStatusAsync.when(
                      data: (friendship) {
                        final friendshipRepository = ref.read(
                          friendshipRepositoryProvider,
                        );
                        final currentUserId = currentUserProfile.uid;
                        final currentUserName = currentUserProfile.name;
                        if (friendship != null &&
                            friendship.status == FriendshipStatus.accepted) {
                          return _buildFriendActionButton(
                            context,
                            'Friends',
                            () async {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => _unfriendDialog(
                                      context,
                                      profile,
                                      friendshipRepository,
                                      currentUserId,
                                      userId,
                                    ),
                              );
                            },
                            isTonal: true,
                          );
                        }
                        if (friendship != null &&
                            friendship.status == FriendshipStatus.pending) {
                          if (friendship.senderId == currentUserId) {
                            return _buildFriendActionButton(
                              context,
                              'Request Sent',
                              null,
                              isTonal: true,
                            );
                          } else {
                            return _buildFriendActionButton(
                              context,
                              'Accept Request',
                              () async {
                                await friendshipRepository.acceptFriendRequest(
                                  friendshipId: friendship.id,
                                  currentUserId: currentUserId,
                                  otherUserId: userId,
                                  currentUserName: currentUserName,
                                );
                                showFloatingSnackBar(
                                  context,
                                  'You are now friends with ${profile.name}!',
                                );
                              },
                            );
                          }
                        }
                        return _buildFriendActionButton(
                          context,
                          'BeFriend',
                          () async {
                            await friendshipRepository.sendFriendRequest(
                              senderId: currentUserId,
                              senderName: currentUserName,
                              receiverId: userId,
                            );
                            showFloatingSnackBar(
                              context,
                              'Friend request sent to ${profile.name}.',
                            );
                          },
                          icon: '🫂',
                        );
                      },
                      loading:
                          () => Center(
                            child: SizedBox(
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Stats
                _StatsGlanceRow(
                  isCurrentUser: isCurrentUser,
                  friends: friendsCount,
                  interestsToday: dailyInterestsCount.value ?? 0,
                  requests: pendingFriendRequestsCount.value ?? 0,
                ),
                // Main Content Cards
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (hasBio || hasTags)
                        ProfileInfoCard(
                          title: 'About',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasBio)
                                Text(
                                  profile.shortBio,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                ),
                              if (hasBio && hasTags) const SizedBox(height: 16),
                              if (hasTags) InterestsSection(tags: profile.tags),
                            ],
                          ),
                        ),
                      if (hasSocial) ...[
                        const SizedBox(height: 16),
                        ProfileInfoCard(
                          title: 'Social Links',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if ((profile.socialHandles['instagram'] ?? '')
                                  .isNotEmpty)
                                _buildSocialLink(
                                  context,
                                  'Instagram',
                                  '@${profile.socialHandles['instagram']}',
                                  Colors.pinkAccent,
                                  Icons.camera_alt_outlined,
                                ),
                              if ((profile.socialHandles['twitter'] ?? '')
                                  .isNotEmpty)
                                _buildSocialLink(
                                  context,
                                  'Twitter',
                                  '@${profile.socialHandles['twitter']}',
                                  Colors.lightBlueAccent,
                                  Icons.camera_alt,
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      error:
          (e, st) => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Text(
                'Error loading profile: $e',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
    );
  }

  Widget _buildFriendActionButton(
    BuildContext context,
    String text,
    VoidCallback? onPressed, {
    bool isTonal = false,
    String? icon,
  }) {
    final theme = Theme.of(context);
    final isBefriendButton = icon == '🫂';

    const befriendGradient = LinearGradient(
      colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SizedBox(
      width: double.infinity,
      child:
          isTonal
              ? FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
              : isBefriendButton
              ? Container(
                decoration: BoxDecoration(
                  gradient: befriendGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Text(icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
    );
  }

  Widget _unfriendDialog(
    BuildContext context,
    UserProfileModel profile,
    FriendshipRepository friendshipRepository,
    String currentUserId,
    String otherUserId,
  ) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(
        'Unfriend',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: Text(
        'Are you sure you want to unfriend ${profile.name}?',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () async {
            await friendshipRepository.unfriend(
              user1Id: currentUserId,
              user2Id: otherUserId,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
              showFloatingSnackBar(
                context,
                'You have unfriended ${profile.name}.',
              );
            }
          },
          child: const Text('Unfriend'),
        ),
      ],
    );
  }

  Widget _buildSocialLink(
    BuildContext context,
    String platform,
    String handle,
    Color iconColor,
    IconData icon,
  ) {
    final theme = Theme.of(context);
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
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 10),
            Text(
              handle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGlanceRow extends StatelessWidget {
  final bool isCurrentUser;
  final int friends;
  final int interestsToday;
  final int requests;

  const _StatsGlanceRow({
    required this.isCurrentUser,
    required this.friends,
    required this.interestsToday,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _StatChip(
              label: 'Friends',
              value: friends,
              icon: Icons.people_alt_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatChip(
              label: 'Interests',
              value: interestsToday,
              icon: Icons.local_fire_department_rounded,
              color: Colors.redAccent,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _StatChip(
                label: 'Requests',
                value: requests,
                icon: Icons.person_add_alt_1_rounded,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
