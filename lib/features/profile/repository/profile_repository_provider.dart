import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});

final userProfileProvider = FutureProvider.family<UserProfileModel?, String>((
  ref,
  uid,
) async {
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getUserProfile(uid);
});
