// file: lib/features/profile/repository/profile_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/auth/auth_controller.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final userProfileProvider = FutureProvider.family<UserProfileModel?, String>((
  ref,
  uid,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getUserProfile(uid);
});

final currentUserProfileFutureProvider = FutureProvider<UserProfileModel?>((
  ref,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getCurrentUserProfile();
});

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

final currentUserProfileProvider = Provider<UserProfileModel?>((ref) {
  return ref.watch(currentUserProfileStreamProvider).value;
});

final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserProfile = ref.watch(currentUserProfileStreamProvider).value;

  return authState.when(
    data: (user) {
      if (user != null && currentUserProfile != null) {
        final repository = ref.read(profileRepositoryProvider);
        return repository.getAllUserProfilesStream().map((users) {
          return users.where((userProfile) {
            final isFriend =
                currentUserProfile.friends?.contains(userProfile.uid) ?? false;
            final hasValidLocation =
                userProfile.location != null &&
                userProfile.location!.latitude != 0 &&
                userProfile.location!.longitude != 0;
            final isNotCurrentUser = userProfile.uid != currentUserProfile.uid;
            final isNotGhostMode = userProfile.isGhostModeEnabled != true;
            return isFriend &&
                hasValidLocation &&
                isNotCurrentUser &&
                isNotGhostMode;
          }).toList();
        });
      } else {
        return Stream.value([]);
      }
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final dailyInterestsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is AsyncData<User?> && authState.value != null) {
    final userId = authState.value!.uid;
    return ref
        .read(profileRepositoryProvider)
        .getDailyInterestsStream(userId)
        .map((interestsList) => interestsList.length);
  }
  return Stream.value(0);
});

final interestDeletionProvider = Provider((ref) {
  final repo = ref.read(profileRepositoryProvider);
  return (String documentId) => repo.deleteInterest(documentId);
});

final allInterestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is AsyncData<User?> && authState.value != null) {
    final userId = authState.value!.uid;
    return ref
        .read(profileRepositoryProvider)
        .getAllInterestsStream(userId)
        .map(
          (querySnapshot) =>
              querySnapshot.docs
                  .map(
                    (doc) => {
                      ...doc.data() as Map<String, dynamic>,
                      'documentId': doc.id,
                    },
                  )
                  .toList(),
        );
  }
  return Stream.value([]);
});

final searchUsersByNameProvider =
    FutureProvider.family<List<UserProfileModel>, String>((ref, query) {
      if (query.isEmpty) {
        return Future.value([]);
      }
      final profileRepository = ref.read(profileRepositoryProvider);
      return profileRepository.searchUsersByName(query);
    });
