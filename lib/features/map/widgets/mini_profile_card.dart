// file: lib/features/map/widgets/mini_profile_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/map/widgets/interests_section.dart';
import 'package:near_me/features/map/widgets/mini_profile_header.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/features/profile/presentation/view_profile_screen.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/themed_switch_list_tile.dart';

// Maximum daily interests allowed
const int maxDailyInterests = 10;

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
      colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    const reversedGradient = LinearGradient(
      colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)],
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
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
          if (user.tags.isNotEmpty) ...[
            InterestsSection(tags: user.tags),
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
                      onPressed: () async {
                        final localInterestsService = ref.read(
                          localInterestsServiceProvider,
                        );
                        final profileRepo = ref.read(profileRepositoryProvider);
                        final currentDailyCount =
                            await localInterestsService
                                .getDailyInterestsCount();
                        if (currentDailyCount >= maxDailyInterests) {
                          showFloatingSnackBar(
                            context,
                            'Daily limit reached. Try again tomorrow! 😊',
                          );
                          return;
                        }
                        if (currentUser.uid != null && user.uid != null) {
                          await localInterestsService
                              .incrementDailyInterestsCount();
                          await profileRepo.saveInterest(
                            currentUser.uid,
                            user.uid,
                          );
                        }
                        showFloatingSnackBar(
                          context,
                          'Notified to the person!',
                        );
                        Navigator.of(context).pop();
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
          if (isCurrentUser)
            Column(
              children: [
                const SizedBox(height: 10),
                Consumer(
                  builder: (context, ref, child) {
                    final isSharingLocation =
                        ref.watch(mapLocationProvider).isLocationSharingEnabled;
                    return ThemedSwitchListTile(
                      title: 'Share My Location',
                      subtitle:
                          isSharingLocation
                              ? 'Your location is updating automatically.'
                              : 'Your location is paused.',
                      value: isSharingLocation,
                      onChanged: (value) {
                        ref
                            .read(mapLocationProvider.notifier)
                            .toggleLocationSharing(value);
                      },
                      icon: Icons.location_on,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Consumer(
                  builder: (context, ref, child) {
                    final isGhostModeEnabled =
                        ref.watch(mapLocationProvider).isGhostModeEnabled;
                    return ThemedSwitchListTile(
                      title: 'Ghost Mode',
                      subtitle:
                          isGhostModeEnabled
                              ? 'Your pin is hidden from everyone.'
                              : 'Your pin is visible to everyone.',
                      value: isGhostModeEnabled,
                      onChanged: (value) {
                        ref
                            .read(mapLocationProvider.notifier)
                            .toggleGhostMode(value);
                      },
                      icon: Icons.visibility_off,
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final success =
                            await ref
                                .read(mapLocationProvider.notifier)
                                .updateLocationNow();
                        if (success) {
                          showFloatingSnackBar(
                            context,
                            'Location Updated!',
                            leadingIcon: Icons.check_circle,
                            backgroundColor: Colors.green,
                          );
                        } else {
                          showFloatingSnackBar(
                            context,
                            'Location permission denied. Please enable it in settings.',
                            leadingIcon: Icons.error,
                            backgroundColor: Colors.red,
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Update Location Now',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
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
