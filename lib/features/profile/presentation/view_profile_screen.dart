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
import 'package:near_me/widgets/profile_info_card.dart'; // Ensure this file exists and contains ProfileInfoCard

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
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
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
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 28,
                  ), // A slightly larger, modern edit icon
                  color:
                      theme
                          .colorScheme
                          .primary, // Use primary color for consistency
                  onPressed: () {
                    // Navigate to EditProfileScreen, passing the current user's UID
                    context.push('/edit-profile/${profile.uid}');
                  },
                ),
              if (!isCurrentUser) // Example: Message button for other users
                IconButton(
                  icon: const Icon(Icons.message_rounded),
                  color: theme.colorScheme.primary,
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
                      Text(
                        lastActiveText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: lastActiveColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Main Content Card (Conditionally displayed if there's any detail)
                if (hasDetailsContent) ...[
                  const SizedBox(
                    height: 24,
                  ), // Spacing between header and content card
                  ProfileInfoCard(
                    title: 'About & Connections', // A single, overarching title
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start, // Align content within the card
                      children: [
                        // Bio Section (inside the main card)
                        if (hasBio) ...[
                          Text(
                            profile.shortBio!,
                            textAlign: TextAlign.center, // Center bio text
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                              height: 1.5,
                            ),
                          ),
                          // Add divider/spacing if there are more sections below
                          if (hasTags || hasSocial) const SizedBox(height: 16),
                        ],

                        // Interests Section (inside the main card)
                        if (hasTags) ...[
                          Text(
                            'Interests', // Sub-title for interests
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InterestsSection(tags: profile.tags!),
                          // Add divider/spacing if there are more sections below
                          if (hasSocial) const SizedBox(height: 16),
                        ],

                        // Social Media Section (inside the main card)
                        if (hasSocial) ...[
                          Text(
                            'Social Media', // Sub-title for social media
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
                const SizedBox(
                  height: 24,
                ), // More space at the bottom for scrolling
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

  // Private helper method for building social links (reverted from separate widget)
  Widget _buildSocialLink(
    BuildContext context,
    String platform,
    String handle,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        // TODO: Implement opening social media links
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
