import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository(this._firestore);

  Future<void> createOrUpdateProfile(UserProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserProfileModel.fromMap(doc.data()!);
    }
    return null;
  }
}
