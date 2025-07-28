// file: lib/features/profile/repository/profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:near_me/features/profile/model/user_profile_model.dart';
// Note: flutter_riverpod is not needed here, only in the provider file.

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // Create or update a user profile in Firestore
  Future<void> createOrUpdateProfile(UserProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Get profile of any user using UID
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfileModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Get profile of currently logged-in user
  Future<UserProfileModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfileModel.fromMap(doc.data()!);
    }
    return null;
  }

  // New method to save an 'interested' action
  Future<void> saveInterest(String fromUserId, String toUserId) async {
    // Prevent spamming by checking for recent interests from the same user
    final lastInterest =
        await _firestore
            .collection('interests')
            .where('fromUserId', isEqualTo: fromUserId)
            .where('toUserId', isEqualTo: toUserId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (lastInterest.docs.isNotEmpty) {
      final lastTimestamp =
          (lastInterest.docs.first.data()['timestamp'] as Timestamp).toDate();
      if (DateTime.now().difference(lastTimestamp).inHours < 1) {
        // If an interest has been sent in the last hour, do nothing
        return;
      }
    }

    // Add the new interest to the 'interests' collection
    await _firestore.collection('interests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // NEW: Update user's location in Firestore
  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': location,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  // NEW METHOD: To update a single field in a user's profile
  Future<void> updateUserProfileField({
    required String uid,
    required String field,
    required dynamic value,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({field: value});
    } catch (e) {
      debugPrint("Error updating user profile field '$field': $e");
      rethrow;
    }
  }

  // Stream to get all user profiles for map (will be modified in a later step for filtering)
  Stream<List<UserProfileModel>> getAllUserProfilesStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfileModel.fromMap(doc.data()!))
          .toList();
    });
  }
}
