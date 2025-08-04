// file: lib/features/profile/repository/profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // The rest of your methods...
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

    // NEW: Also increment the interested count for the recipient
    // (This part is still useful for the lifetime count on the notifications screen)
    await incrementInterestedCount(toUserId);
  }

  // NEW METHOD: Increment the 'interestedCount' field for a user
  Future<void> incrementInterestedCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'interestedCount': FieldValue.increment(1),
      });
      debugPrint("Interested count incremented for user: $userId");
    } catch (e) {
      debugPrint("Error incrementing interested count: $e");
      await _firestore.collection('users').doc(userId).set({
        'interestedCount': 1,
      }, SetOptions(merge: true));
    }
  }

  // NEW: Update user's location in Firestore
  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': location,
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint('User location and lastActive updated for $userId');
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

  // Stream to get all user profiles for map
  Stream<List<UserProfileModel>> getAllUserProfilesStream() {
    return _firestore
        .collection('users')
        .orderBy('uid') // <--- FIX: Add this explicit orderBy clause
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserProfileModel.fromMap(doc.data()!))
              .toList();
        });
  }

  // --- NEW METHOD: Stream a single user's profile ---
  Stream<UserProfileModel> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfileModel.fromMap(snapshot.data()!);
      }
      return UserProfileModel.empty();
    });
  }

  // ----------------------------------------------------
  // NEW: METHODS FOR THE DAILY/ALL-TIME INTERESTS
  // ----------------------------------------------------

  // NEW METHOD: Stream a list of interests received today
  Stream<List<Map<String, dynamic>>> getDailyInterestsStream(String userId) {
    final startOfToday = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    // Convert to Firestore Timestamp for the query
    final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

    return _firestore
        .collection('interests')
        .where('toUserId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // NEW METHOD: Stream a list of all-time interests
  Stream<List<Map<String, dynamic>>> getAllInterestsStream(String userId) {
    return _firestore
        .collection('interests')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
