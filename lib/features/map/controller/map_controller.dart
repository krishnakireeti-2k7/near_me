import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

final userLocationsProvider = FutureProvider<List<UserProfileModel>>((
  ref,
) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').get();

  return snapshot.docs.map((doc) {
    return UserProfileModel.fromMap(doc.data());
  }).toList();
});
