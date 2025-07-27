import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final profileAsync = ref.watch(userProfileProvider(uid));
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      profile.profileImageUrl.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl)
                          : null,
                  child:
                      profile.profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 48)
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${profile.collegeYear} • ${profile.branch}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children:
                      profile.interests
                          .map((i) => Chip(label: Text(i)))
                          .toList(),
                ),
                const SizedBox(height: 12),
                if ((profile.socialHandles['instagram'] ?? '').isNotEmpty)
                  Text(
                    "Instagram: @${profile.socialHandles['instagram']}",
                    style: TextStyle(color: Colors.purple),
                  ),
                if ((profile.socialHandles['twitter'] ?? '').isNotEmpty)
                  Text(
                    "Twitter: @${profile.socialHandles['twitter']}",
                    style: TextStyle(color: Colors.blue),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  onPressed: () {
                    // TODO: Navigate to edit profile screen
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
