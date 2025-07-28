// file: lib/router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/auth/auth_view.dart';
import 'package:near_me/features/profile/presentation/create_profile_screen.dart';
import 'package:near_me/features/map/presentation/map_screen.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/presentation/view_profile_screen.dart';
// IMPORT THE NEW EDIT PROFILE SCREEN
import 'package:near_me/features/profile/presentation/edit_profile_screen.dart'; // <--- ADD THIS IMPORT

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final auth = authAsync.asData?.value;

  final currentProfileAsync =
      auth != null
          ? ref.watch(userProfileProvider(auth.uid))
          : const AsyncValue.data(null);
  final currentProfile = currentProfileAsync.asData?.value;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: (context, state) {
      // --- START DEBUG PRINTS ---
      print('--- GoRouter Redirect Evaluation ---');
      print('Current Location: ${state.matchedLocation}');
      print(
        'Auth Async: isLoading=${authAsync.isLoading}, hasError=${authAsync.hasError}, data=${authAsync.asData?.value != null ? 'User Exists' : 'No User'}',
      );
      if (authAsync.hasError) {
        print('Auth Error: ${authAsync.error}');
      }
      print(
        'Profile Async: isLoading=${currentProfileAsync.isLoading}, hasError=${currentProfileAsync.hasError}, data=${currentProfileAsync.asData?.value != null ? 'Profile Exists' : 'No Profile'}',
      );
      if (currentProfileAsync.hasError) {
        print('Profile Error: ${currentProfileAsync.error}');
      }
      // --- END DEBUG PRINTS ---

      // 1. If authentication or profile data is still loading, stay on the current route.
      if (authAsync.isLoading || currentProfileAsync.isLoading) {
        print(
          'Status: Loading Auth or Profile. Staying on current route (null redirect).',
        );
        return null;
      }

      // 2. If authentication failed (hasError) or no user is logged in
      if (authAsync.hasError || auth == null) {
        print(
          'Status: Auth error or No User. Redirecting to /login if not already there.',
        );
        return (state.matchedLocation != '/login') ? '/login' : null;
      }

      // 3. If authenticated but profile loading failed (hasError) or profile doesn't exist
      // And the current route is NOT the edit-profile route.
      // This allows the /edit-profile route to still fetch data even if it's currently null
      // for the purpose of pre-filling.
      final isCreatingOrEditingProfile =
          state.matchedLocation == '/create-profile' ||
          state.matchedLocation.startsWith('/edit-profile');

      if (currentProfileAsync.hasError || currentProfile == null) {
        print(
          'Status: Profile error or No Profile found. Redirecting to /create-profile if not already there.',
        );
        // If they are on an edit/create profile screen, don't redirect away
        if (isCreatingOrEditingProfile) {
          return null; // Stay on the create/edit screen
        }
        return '/create-profile'; // Redirect to create profile
      }

      // If we reach here, user is authenticated and has a profile.
      // 4. If the user is authenticated, has a profile, and is on a setup-related route,
      // redirect them to the map.
      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/create-profile' ||
          state.matchedLocation == '/') {
        print(
          'Status: Authenticated and has Profile. Redirecting from setup route to /map.',
        );
        return '/map';
      }

      // 5. All conditions met, allow navigation to the requested route.
      print(
        'Status: Authenticated, has Profile, and on valid route. Allowing current navigation (null redirect).',
      );
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, state) => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const AuthView()),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),

      GoRoute(
        path: '/my-profile',
        name: 'myProfile',
        builder: (context, state) {
          final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserUid == null) {
            return const AuthView(); // Should ideally be handled by redirect
          }
          return ViewProfileScreen(userId: currentUserUid, isCurrentUser: true);
        },
      ),

      GoRoute(
        path: '/profile/:uid',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['uid']!;
          final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
          return ViewProfileScreen(
            userId: userId,
            isCurrentUser: currentUserUid == userId,
          );
        },
      ),

      // ADD THE NEW EDIT PROFILE ROUTE HERE
      GoRoute(
        path: '/edit-profile/:userId', // Define the path with a parameter
        name:
            'editProfile', // Give it a name for easier navigation (optional but good practice)
        builder: (context, state) {
          final userId =
              state.pathParameters['userId']!; // Extract userId from path
          return EditProfileScreen(userId: userId);
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
