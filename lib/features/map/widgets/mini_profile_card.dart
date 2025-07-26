import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

// Change from StatelessWidget to ConsumerWidget
class MiniProfileCard extends ConsumerWidget {
  final UserProfileModel user;

  const MiniProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add WidgetRef ref
    // Get the current user's UID to use for saving the interest
    final currentUser = ref.watch(authStateProvider).value;

    String? imageUrlToShow;
    if (user.profileImageUrl.isNotEmpty) {
      imageUrlToShow = user.profileImageUrl;
    } else if ((user as dynamic).googlePhotoUrl != null &&
        (user as dynamic).googlePhotoUrl.isNotEmpty) {
      imageUrlToShow = (user as dynamic).googlePhotoUrl;
    } else {
      imageUrlToShow = null;
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage:
                    imageUrlToShow != null
                        ? NetworkImage(imageUrlToShow)
                        : null,
                child:
                    imageUrlToShow == null
                        ? const Icon(Icons.person, size: 36)
                        : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${user.collegeYear} • ${user.branch}",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              if (user.interests.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children:
                      user.interests
                          .map((interest) => Chip(label: Text(interest)))
                          .toList(),
                ),
              const SizedBox(height: 8),
              if ((user.socialHandles['instagram'] ?? '').isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text("Instagram: @${user.socialHandles['instagram']}"),
                  ],
                ),
              if ((user.socialHandles['twitter'] ?? '').isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.alternate_email,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text("Twitter: @${user.socialHandles['twitter']}"),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.whatshot, color: Colors.white),
                label: const Text('Interested'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // Only allow the button to be pressed if the current user is valid
                  // and is not trying to "interest" their own profile.
                  if (currentUser != null && currentUser.uid != user.uid) {
                    ref
                        .read(profileRepositoryProvider)
                        .saveInterest(currentUser.uid, user.uid);
                    // Optional: show a snackbar to confirm the action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are interested!')),
                    );
                  } else {
                    // Optional: show a snackbar if the user is not logged in or is viewing their own profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot perform this action.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
