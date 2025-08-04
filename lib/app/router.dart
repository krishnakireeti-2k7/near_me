// file: lib/app/router.dart

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
import 'package:near_me/features/profile/presentation/edit_profile_screen.dart';
import 'package:near_me/features/map/presentation/loading_screen.dart'; // <--- ADD THIS IMPORT

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
      // 1. If authentication data is still loading, stay on the current route.
      // We no longer wait for the profile here to avoid the timing issue.
      if (authAsync.isLoading) {
        return null;
      }

      // 2. If no user is logged in, redirect to the login page.
      if (auth == null) {
        return (state.matchedLocation != '/login') ? '/login' : null;
      }

      // If the user is authenticated, check for a profile.
      final isCreatingOrEditingProfile =
          state.matchedLocation == '/create-profile' ||
          state.matchedLocation.startsWith('/edit-profile');

      // 3. If a user is authenticated but has no profile, redirect to the create profile screen.
      if (currentProfile == null && !isCreatingOrEditingProfile) {
        return '/create-profile';
      }

      // 4. If the user is authenticated, has a profile, and is on a setup-related route,
      // redirect them to the map.
      if (currentProfile != null &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/create-profile' ||
              state.matchedLocation == '/')) {
        return '/map';
      }

      // 5. Otherwise, allow navigation to the requested route.
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, state) =>
                const LoadingScreen(), // <-- USE THE NEW LOADING SCREEN
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
            return const AuthView();
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
      GoRoute(
        path: '/edit-profile/:userId',
        name: 'editProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
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
