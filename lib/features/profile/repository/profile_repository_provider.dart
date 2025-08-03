// file: lib/features/profile/repository/profile_repository_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/auth/auth_controller.dart'; // Assuming authStateProvider is here

// Provide the ProfileRepository with both Firestore and Auth instances
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// Get any user's profile by UID
final userProfileProvider = FutureProvider.family<UserProfileModel?, String>((
  ref,
  uid,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getUserProfile(uid);
});

// Get current logged-in user's profile (as a FutureProvider for one-time fetch)
final currentUserProfileFutureProvider = FutureProvider<UserProfileModel?>((
  ref,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getCurrentUserProfile();
});

// StreamProvider: Stream for the currently authenticated user's profile
final currentUserProfileStreamProvider = StreamProvider<UserProfileModel?>((
  ref,
) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.read(profileRepositoryProvider).streamUserProfile(user.uid);
      } else {
        return Stream.value(null);
      }
    },
    loading: () => Stream.value(null),
    error: (err, stack) {
      print('Error in currentUserProfileStreamProvider: $err');
      return Stream.value(null);
    },
  );
});

// A simple Provider to get the current UserProfileModel synchronously from the stream
final currentUserProfileProvider = Provider<UserProfileModel?>((ref) {
  return ref.watch(currentUserProfileStreamProvider).value;
});

// Stream to get all user profiles for the map
final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getAllUserProfilesStream();
});

// ----------------------------------------------------
// NEW: PROVIDERS FOR THE DAILY/ALL-TIME INTERESTS
// ----------------------------------------------------

// New StreamProvider: To get the number of interests received today
final dailyInterestsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is AsyncData<User?> && authState.value != null) {
    final userId = authState.value!.uid;
    // Use the new repository method and map the list to a count
    return ref
        .read(profileRepositoryProvider)
        .getDailyInterestsStream(userId)
        .map((interests) => interests.length);
  }
  return Stream.value(0);
});

// New StreamProvider: To get the full list of interests (for the notifications screen)
final allInterestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is AsyncData<User?> && authState.value != null) {
    final userId = authState.value!.uid;
    return ref.read(profileRepositoryProvider).getAllInterestsStream(userId);
  }
  return Stream.value([]);
});
