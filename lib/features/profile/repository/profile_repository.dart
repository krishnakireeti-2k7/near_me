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

  Future<UserProfileModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfileModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> saveInterest(String fromUserId, String toUserId) async {
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
        return;
      }
    }

    await _firestore.collection('interests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'timestamp': Timestamp.now(),
    });

    await incrementInterestedCount(toUserId);
  }

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

  // Stream for all user profiles for map
  Stream<List<UserProfileModel>> getAllUserProfilesStream() {
    return _firestore.collection('users').orderBy('uid').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => UserProfileModel.fromMap(doc.data()!))
          .toList();
    });
  }

  Stream<UserProfileModel> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfileModel.fromMap(snapshot.data()!);
      }
      return UserProfileModel.empty();
    });
  }

  Stream<QuerySnapshot> getAllInterestsStream(String userId) {
    return _firestore
        .collection('interests')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteInterest(String documentId) async {
    try {
      await _firestore.collection('interests').doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting interest: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getDailyInterestsStream(String userId) {
    final startOfToday = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

    return _firestore
        .collection('interests')
        .where('toUserId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<UserProfileModel>> searchUsersByName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final queryLowercase = query.toLowerCase();

    final usersSnapshot =
        await _firestore
            .collection('users')
            .where('name_lowercase', isGreaterThanOrEqualTo: queryLowercase)
            .where('name_lowercase', isLessThan: queryLowercase + '\uf8ff')
            .get();

    return usersSnapshot.docs
        .map((doc) => UserProfileModel.fromMap(doc.data()!))
        .toList();
  }

  // NEW METHOD: This is the fix for your error
  Future<void> updateGhostModeStatus(
    String userId,
    bool isGhostModeEnabled,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'isGhostModeEnabled': isGhostModeEnabled,
    });
  }
}
