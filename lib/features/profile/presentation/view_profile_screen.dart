// file: lib/features/profile/presentation/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Still used for internal navigation like logout or future edits
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isCurrentUser ? 'My Profile' : 'User Profile'),
            ),
            body: const Center(child: Text('Profile not found.')),
          );
        }

        String lastActiveText = "Never active";
        Color lastActiveColor = Colors.grey;
        if (profile.lastActive != null) {
          final DateTime lastActiveDateTime = profile.lastActive!.toDate();
          lastActiveText = 'Last active: ${timeago.format(lastActiveDateTime)}';
          if (DateTime.now().difference(lastActiveDateTime).inMinutes <= 5) {
            lastActiveColor = Colors.green[700]!;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isCurrentUser ? 'My Profile' : profile.name),
            leading:
                isCurrentUser
                    ? null // No leading for current user if drawer is handled elsewhere
                    : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            actions: [
              // TEMPORARILY REMOVED: Edit button for current user, until EditProfileScreen is implemented
              // if (isCurrentUser)
              //   IconButton(
              //     icon: const Icon(Icons.edit),
              //     onPressed: () {
              //       // context.go('/edit-profile'); // This route is now removed from GoRouter
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Edit Profile coming soon!')),
              //       );
              //     },
              //   ),
              if (!isCurrentUser) // Example: Message button for other users
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat feature coming soon!'),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                            size: 60,
                            color: Colors.grey[600],
                          )
                          : null,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 24),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  lastActiveText,
                  style: TextStyle(
                    fontSize: 14,
                    color: lastActiveColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                if (profile.shortBio != null && profile.shortBio!.isNotEmpty) ...[
                  Text(
                    profile.shortBio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                ],

                if (profile.tags != null && profile.tags!.isNotEmpty) ...[
                  InterestsSection(tags: profile.tags!),
                  const SizedBox(height: 16),
                ],

                if ((profile.socialHandles['instagram'] ?? '').isNotEmpty ||
                    (profile.socialHandles['twitter'] ?? '').isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Social Media',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if ((profile.socialHandles['instagram'] ?? '').isNotEmpty)
                  _buildSocialLink(
                    context,
                    'Instagram',
                    '@${profile.socialHandles['instagram']}',
                    Colors.purple,
                    Icons.camera_alt,
                  ),
                if ((profile.socialHandles['twitter'] ?? '').isNotEmpty)
                  _buildSocialLink(
                    context,
                    'Twitter',
                    '@${profile.socialHandles['twitter']}',
                    Colors.blue,
                    Icons.mail,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (e, st) =>
              Scaffold(body: Center(child: Text('Error loading profile: $e'))),
    );
  }

  Widget _buildSocialLink(
    BuildContext context,
    String platform,
    String handle,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '$platform: $handle',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
