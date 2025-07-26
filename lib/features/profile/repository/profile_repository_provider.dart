import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';

// Provide the ProfileRepository with both Firestore and Auth instances
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

// Get current logged-in user's profile
final currentUserProfileProvider = FutureProvider<UserProfileModel?>((
  ref,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getCurrentUserProfile();
});
