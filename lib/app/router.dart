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

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final auth = authAsync.asData?.value;

  // IMPORTANT: Ensure auth.uid is not null before watching userProfileProvider
  final currentProfileAsync =
      auth != null
          ? ref.watch(userProfileProvider(auth.uid))
          : const AsyncValue.data(null); // No profile if not authenticated
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
      // This prevents premature redirects.
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
      if (currentProfileAsync.hasError || currentProfile == null) {
        print(
          'Status: Profile error or No Profile found. Redirecting to /create-profile if not already there.',
        );
        return (state.matchedLocation != '/create-profile')
            ? '/create-profile'
            : null;
      }

      // If we reach here, user is authenticated and has a profile.
      // It's safe to call initPushNotifications here, but typically it's better
      // to do this once when MapScreen is built to avoid repeated calls in redirects.
      // Temporarily REMOVING from here based on previous suggestion to move to MapScreen.
      // ref.read(authControllerProvider).initPushNotifications();

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
