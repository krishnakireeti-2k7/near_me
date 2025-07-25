import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) {
          return UserProfileModel.fromMap(doc.data());
        })
        .where((user) => user.location != null)
        .toList();
  });
});
