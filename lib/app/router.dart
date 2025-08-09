// file: lib/app/router.dart

import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/auth/auth_view.dart';
import 'package:near_me/features/map/widgets/searc_results_screen.dart';
import 'package:near_me/features/notificatons/notifications_screen.dart';
import 'package:near_me/features/profile/presentation/create_profile_screen.dart';
import 'package:near_me/features/map/presentation/map_screen.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/presentation/view_profile_screen.dart';
import 'package:near_me/features/profile/presentation/edit_profile_screen.dart';
import 'package:near_me/features/map/presentation/loading_screen.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart'; 
// NEW: A combined provider that watches both auth state and profile state
final bootstrapperProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final auth = ref.watch(authStateProvider);

  if (auth.isLoading) {
    yield {'status': 'loading'};
    return;
  }

  final user = auth.value;
  if (user == null) {
    yield {'status': 'unauthenticated'};
    return;
  }

  // Watch the user profile stream. This provider will yield
  // a new value whenever the user profile changes.
  await for (final userProfile in ref.watch(
    currentUserProfileStreamProvider.stream,
  )) {
    if (userProfile == null) {
      yield {'status': 'needs-profile', 'user': user};
    } else {
      yield {'status': 'authenticated', 'user': user, 'profile': userProfile};
    }
  }
});

final routerProvider = Provider<GoRouter>((ref) {
  final bootstrapper = ref.watch(bootstrapperProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(bootstrapperProvider.stream),
    ),
    redirect: (context, state) {
      final status = bootstrapper.asData?.value['status'];

      if (bootstrapper.isLoading) {
        return null;
      }

      if (status == 'unauthenticated' || status == null) {
        return (state.matchedLocation != '/login') ? '/login' : null;
      }

      if (status == 'needs-profile') {
        final isCreatingOrEditingProfile =
            state.matchedLocation == '/create-profile' ||
            state.matchedLocation.startsWith('/edit-profile');

        return !isCreatingOrEditingProfile ? '/create-profile' : null;
      }

      // User is authenticated and has a profile
      if (status == 'authenticated') {
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/create-profile' ||
            state.matchedLocation == '/';

        return isAuthRoute ? '/map' : null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoadingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AuthView()),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/interests',
        builder: (context, state) => const NotificationsScreen(),
      ),
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
      GoRoute(
        path: '/searchResults',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final places = data['places'] as List<Prediction>;
          final users = data['users'] as List<UserProfileModel>;
          final query = data['query'] as String;

          return SearchResultsScreen(
            places: places,
            users: users,
            initialQuery: query,
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
