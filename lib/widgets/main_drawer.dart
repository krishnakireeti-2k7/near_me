// file: lib/widgets/main_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/logout_dialog.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
// NOTE: This import is no longer needed since we are using GoRouter
// import 'package:near_me/features/profile/presentation/friends_list_screen.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(currentUserProfileStreamProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final dailyInterestsCount = ref.watch(dailyInterestsCountProvider);
    final pendingFriendRequestsCount = ref.watch(
      pendingFriendRequestsCountProvider,
    );

    final totalNotificationCount =
        (dailyInterestsCount.value ?? 0) +
        (pendingFriendRequestsCount.value ?? 0);

    return Drawer(
      child: Column(
        children: [
          SafeArea(
            child: userProfileAsyncValue.when(
              data: (userProfile) {
                final String accountName = userProfile?.name ?? 'Guest';
                final String accountEmail = firebaseUser?.email ?? '';
                final String? imageUrl =
                    userProfile?.profileImageUrl?.isNotEmpty == true
                        ? userProfile!.profileImageUrl
                        : firebaseUser?.photoURL;

                return Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.onSurface.withOpacity(
                          0.08,
                        ),
                        backgroundImage:
                            imageUrl != null && imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                        child:
                            imageUrl == null || imageUrl.isEmpty
                                ? Icon(
                                  Icons.person,
                                  size: 36,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accountName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              accountEmail,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (e, st) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: Text("Error loading profile")),
                  ),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.map,
                  title: 'Map',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_circle_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      context.go('/edit-profile/$uid');
                    } else {
                      context.go('/login');
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: 'My Friends',
                  onTap: () {
                    Navigator.of(context).pop();
                    // ✅ CHANGE: Use GoRouter's push method
                    context.push('/friends-list');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.local_fire_department_rounded,
                  title: 'Notifications',
                  trailing:
                      totalNotificationCount > 0
                          ? Text(
                            '${totalNotificationCount}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/notifications');
                  },
                ),
                const Divider(height: 32, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Add navigation
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () async {
                    await LogoutDialog.show(context, ref);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.onSurface.withOpacity(0.08),
        foregroundColor: colorScheme.onSurface,
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
