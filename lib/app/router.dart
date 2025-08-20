import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/auth/auth_view.dart';
import 'package:near_me/features/map/presentation/map_screen.dart';
import 'package:near_me/features/map/widgets/searc_results_screen.dart';
import 'package:near_me/features/notificatons/notifications_screen.dart';
import 'package:near_me/features/profile/presentation/create_profile_screen.dart';
import 'package:near_me/features/profile/presentation/view_profile_screen.dart';
import 'package:near_me/features/profile/presentation/edit_profile_screen.dart';
import 'package:near_me/features/map/presentation/loading_screen.dart';
import 'package:near_me/features/profile/presentation/friends_list_screen.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

// ✅ NEW: Simplified bootstrapperProvider. It only checks authentication status.
final bootstrapperProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final authAsync = ref.watch(authStateProvider);
  if (authAsync.isLoading) {
    yield {'status': 'loading'};
    return;
  }

  final user = authAsync.value;
  if (user == null) {
    yield {'status': 'unauthenticated'};
  } else {
    yield {'status': 'authenticated', 'user': user};
  }
});

class BootstrapperChangeNotifier extends ChangeNotifier {
  BootstrapperChangeNotifier(this.ref) {
    // Listen to the main auth state
    ref.listen<AsyncValue<Map<String, dynamic>>>(bootstrapperProvider, (
      previous,
      next,
    ) {
      if (previous?.value?['status'] != next.value?['status']) {
        notifyListeners();
      }
    });
    // ✅ NEW: Listen to the profile creation status flag
    ref.listen<bool>(profileCreationStatusProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final bootstrapperNotifier = BootstrapperChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: bootstrapperNotifier,
    redirect: (context, state) {
      final bootstrapper = ref.read(bootstrapperProvider);
      // ✅ NEW: Read the profile creation status directly
      final profileCreated = ref.watch(profileCreationStatusProvider);

      if (bootstrapper.isLoading) {
        return '/';
      }

      final status = bootstrapper.asData?.value['status'];
      final user = bootstrapper.asData?.value['user'];

      if (status == 'unauthenticated') {
        return state.matchedLocation != '/login' ? '/login' : null;
      }

      // ✅ MODIFIED: Use the new state provider for redirect logic
      if (status == 'authenticated' && !profileCreated) {
        final isCreatingProfile = state.matchedLocation == '/create-profile';
        return !isCreatingProfile ? '/create-profile' : null;
      }

      if (status == 'authenticated' && profileCreated) {
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
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
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
          final places = data['places'] as List<AutocompletePrediction>;
          final users = data['users'] as List<UserProfileModel>;
          final query = data['query'] as String;
          return SearchResultsScreen(
            places: places,
            users: users,
            initialQuery: query,
          );
        },
      ),
      GoRoute(
        path: '/friends-list',
        builder: (context, state) => const FriendsListScreen(),
      ),
    ],
  );
});
