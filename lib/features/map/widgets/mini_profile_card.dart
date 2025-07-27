// file: mini_profile_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/map/widgets/interests_section.dart';
import 'package:near_me/features/map/widgets/mini_profile_header.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';

class MiniProfileCard extends ConsumerWidget {
  final UserProfileModel user;

  const MiniProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isCurrentUser = currentUser?.uid == user.uid;

    String? imageUrlToShow;
    if (user.profileImageUrl.isNotEmpty) {
      imageUrlToShow = user.profileImageUrl;
    } else if ((user as dynamic).googlePhotoUrl != null &&
        (user as dynamic).googlePhotoUrl.isNotEmpty) {
      imageUrlToShow = (user as dynamic).googlePhotoUrl;
    } else {
      imageUrlToShow = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniProfileHeader(
                user: user,
                isCurrentUser: isCurrentUser,
                imageUrlToShow: imageUrlToShow,
              ),
              InterestsSection(interests: user.interests),

              if ((user.socialHandles['instagram'] ?? '').isNotEmpty ||
                  (user.socialHandles['twitter'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                if ((user.socialHandles['instagram'] ?? '').isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Instagram: @${user.socialHandles['instagram']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                if ((user.socialHandles['twitter'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alternate_email,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Twitter: @${user.socialHandles['twitter']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
              if (currentUser != null && !isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.whatshot,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Interested',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              ref
                                  .read(profileRepositoryProvider)
                                  .saveInterest(currentUser.uid, user.uid);
                              Navigator.of(context).pop();
                              showFloatingSnackBar(
                                context,
                                'Notified to the person!',
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            showFloatingSnackBar(
                              context,
                              'Chat feature coming soon!',
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chat',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '(Coming Soon)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
