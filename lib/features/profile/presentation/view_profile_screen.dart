// file: lib/features/profile/presentation/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import for navigation
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewProfileScreen extends ConsumerWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final profileAsync = ref.watch(
      userProfileProvider(uid),
    ); // Using FutureProvider here

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: Center(child: Text('Profile not found. Please create one.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.go(
                    '/edit-profile',
                  ); // Navigate to edit profile screen
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            // Use SingleChildScrollView for potential overflow
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60, // Slightly larger avatar
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
                          ) // Larger icon
                          : null,
                  backgroundColor: Colors.grey[200], // Placeholder background
                ),
                const SizedBox(height: 24),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24, // Slightly larger font
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // REMOVED: "${profile.collegeYear} • ${profile.branch}"
                // This line is removed as these fields are no longer in the model.

                // NEW: Display short bio
                if (profile.shortBio.isNotEmpty) ...[
                  Text(
                    profile.shortBio,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                ],

                // MODIFIED: Use profile.tags instead of profile.interests
                if (profile.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8, // Spacing between chips
                    runSpacing: 4, // Spacing between lines of chips
                    alignment: WrapAlignment.center,
                    children:
                        profile.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Display Social Handles
                if ((profile.socialHandles['instagram'] ?? '').isNotEmpty) ...[
                  _buildSocialLink(
                    context,
                    'Instagram',
                    '@${profile.socialHandles['instagram']}',
                    Colors.purple,
                    Icons.camera_alt, // Placeholder for Instagram icon
                  ),
                ],
                if ((profile.socialHandles['twitter'] ?? '').isNotEmpty) ...[
                  _buildSocialLink(
                    context,
                    'Twitter',
                    '@${profile.socialHandles['twitter']}',
                    Colors.blue,
                    Icons.mail, // Placeholder for Twitter icon
                  ),
                ],

                // Add more social links if needed, e.g., LinkedIn, GitHub
                const SizedBox(height: 24),
                // The Edit Profile button is now an IconButton in the AppBar actions
              ],
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (e, st) => Scaffold(
            body: Center(child: Text('Error loading profile: $e\n$st')),
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
