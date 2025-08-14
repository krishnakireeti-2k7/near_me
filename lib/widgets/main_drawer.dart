// file: lib/widgets/main_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/logout_dialog.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(currentUserProfileStreamProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final dailyInterestsCount = ref.watch(dailyInterestsCountProvider);
    final pendingFriendRequestsCount = ref.watch(
      pendingFriendRequestsCountProvider,
    );

    final totalNotificationCount =
        (dailyInterestsCount.value ?? 0) +
        (pendingFriendRequestsCount.value ?? 0);

    final friendsCount = userProfileAsyncValue.maybeWhen(
      data: (profile) => profile?.friends?.length ?? 0,
      orElse: () => 0,
    );

    return Drawer(
      width: 330.0,
      child: Column(
        children: [
          SafeArea(
            child: userProfileAsyncValue.when(
              data: (userProfile) {
                final String accountName = userProfile?.name ?? 'Guest';
                final String accountEmail = firebaseUser?.email ?? '';
                final String? imageUrl =
                    (userProfile?.profileImageUrl?.isNotEmpty ?? false)
                        ? userProfile!.profileImageUrl
                        : firebaseUser?.photoURL;
                final String? uid = firebaseUser?.uid;

                return _GradientProfileHeader(
                  name: accountName,
                  email: accountEmail.isNotEmpty ? accountEmail : null,
                  imageUrl: imageUrl,
                  onOpenProfile: () {
                    Navigator.of(context).pop();
                    if (uid != null) {
                      context.go('/edit-profile/$uid');
                    } else {
                      context.go('/login');
                    }
                  },
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _StatsGlanceRow(
              friends: friendsCount,
              interestsToday: dailyInterestsCount.value ?? 0,
              requests: pendingFriendRequestsCount.value ?? 0,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _DrawerButton(
                    icon: Icons.people_alt_rounded,
                    title: 'My Friends',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/friends-list');
                    },
                  ),
                  const SizedBox(height: 12),
                  _DrawerButton(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    badgeCount: totalNotificationCount,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/notifications');
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _LogoutButton(
              onTap: () async {
                await LogoutDialog.show(context, ref);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final int badgeCount;
  final VoidCallback onTap;

  const _DrawerButton({
    required this.icon,
    required this.title,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // ✅ Increased elevation for a more prominent shadow
          elevation: 7,
          shadowColor: Colors.black.withOpacity(0.3),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF08D0E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _StatsGlanceRow extends StatelessWidget {
  final int friends;
  final int interestsToday;
  final int requests;

  const _StatsGlanceRow({
    required this.friends,
    required this.interestsToday,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Friends',
            value: friends,
            icon: Icons.people_alt_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Interests',
            value: interestsToday,
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Requests',
            value: requests,
            icon: Icons.person_add_alt_1_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33F08D0E), Color(0x33FFA502)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        // ✅ The box shadow has been removed to create a lighter, less shadowy look
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.95),
            child: Icon(icon, size: 16, color: Colors.black87),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientProfileHeader extends StatelessWidget {
  final String name;
  final String? email;
  final String? imageUrl;
  final VoidCallback onOpenProfile;

  const _GradientProfileHeader({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFff6b6b), Color(0xFFf08d0e)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.95),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage:
                    (imageUrl != null && imageUrl!.isNotEmpty)
                        ? NetworkImage(imageUrl!)
                        : null,
                child:
                    (imageUrl == null || imageUrl!.isEmpty)
                        ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.black,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.85),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _GlassButton(
                    onTap: onOpenProfile,
                    icon: Icons.open_in_new,
                    label: 'Open Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _GlassButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.16),
          border: Border.all(color: Colors.white.withOpacity(.55)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
