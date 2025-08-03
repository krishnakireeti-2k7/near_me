// file: lib/widgets/main_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart'; // This contains currentUserProfileStreamProvider
import 'package:firebase_auth/firebase_auth.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current user's profile using the StreamProvider to get AsyncValue
    final userProfileAsyncValue = ref.watch(
      currentUserProfileStreamProvider,
    ); // <-- CHANGED THIS LINE
    // Get the current Firebase user to access their email
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          userProfileAsyncValue.when(
            // Now you can use .when correctly
            data: (userProfile) {
              // userProfile here is UserProfileModel?
              return UserAccountsDrawerHeader(
                accountName: Text(userProfile?.name ?? 'Guest'),
                accountEmail: Text(firebaseUser?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage:
                      userProfile?.profileImageUrl != null &&
                              userProfile!.profileImageUrl.isNotEmpty
                          ? NetworkImage(userProfile.profileImageUrl)
                          : null,
                  child:
                      userProfile?.profileImageUrl == null ||
                              userProfile!.profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 48)
                          : null,
                ),
                decoration: const BoxDecoration(color: Colors.blue),
              );
            },
            loading:
                () => const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            error:
                (e, st) => const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Center(
                    child: Text(
                      'Error loading profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              context.pop(); // Close the drawer
              final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserUid != null) {
                // Navigate directly to the EditProfileScreen for the current user
                context.go('/edit-profile/$currentUserUid');
              } else {
                // Handle case where user is not logged in (though router redirect should catch this)
                context.go('/login');
              }
            },
          ),
          // Add other ListTiles for other drawer items if you have them
        ],
      ),
    );
  }
}
