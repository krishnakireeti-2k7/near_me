// file: lib/features/map/widgets/mini_profile_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/map/widgets/interests_section.dart';
import 'package:near_me/features/map/widgets/mini_profile_header.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/features/profile/presentation/view_profile_screen.dart';

class MiniProfileCard extends ConsumerWidget {
  final UserProfileModel user;

  const MiniProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isCurrentUser = currentUser?.uid == user.uid;

    String? imageUrlToShow =
        user.profileImageUrl.isNotEmpty
            ? user.profileImageUrl
            : (isCurrentUser ? currentUser?.photoURL : null);

    const primaryGradient = LinearGradient(
      colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)], // Red/Orange gradient
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    const reversedGradient = LinearGradient(
      colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)], // Same colors
      begin: Alignment.centerRight, // Reversed direction
      end: Alignment.centerLeft,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // --- MODIFIED HERE TO MAKE IT DARKER ---
            color: const Color.fromRGBO(
              0,
              0,
              0,
              0.3,
            ), // Increased opacity from 0.1 to 0.3
            // --- END MODIFICATION ---
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniProfileHeader(
            user: user,
            isCurrentUser: isCurrentUser,
            imageUrlToShow: imageUrlToShow,
          ),
          const SizedBox(height: 12),

          if (user.tags != null && user.tags!.isNotEmpty) ...[
            InterestsSection(tags: user.tags!),
            const SizedBox(height: 12),
          ],

          if ((user.socialHandles['instagram'] ?? '').isNotEmpty ||
              (user.socialHandles['twitter'] ?? '').isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            if ((user.socialHandles['instagram'] ?? '').isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.camera_alt, size: 18, color: Colors.purple),
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
                    const Icon(Icons.mail, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      "Twitter: @${user.socialHandles['twitter']}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],

          if (currentUser != null && !isCurrentUser)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: reversedGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ElevatedButton.icon(
                      icon: const Text(
                        '🔥',
                        style: TextStyle(
                          fontSize: 20,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black,
                              offset: const Offset(0.8, 0.8),
                            ),
                          ],
                        ),
                      ),
                      label: const Text(
                        'Interested',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'View Full Profile',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (ctx) => ViewProfileScreen(
                                  userId: user.uid,
                                  isCurrentUser: false,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
