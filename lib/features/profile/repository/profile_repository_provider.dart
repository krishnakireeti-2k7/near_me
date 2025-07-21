import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});
