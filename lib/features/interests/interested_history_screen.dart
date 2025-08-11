// file: lib/features/interests/interested_history_screen.dart

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

  // ... (all other methods remain the same) ...

  // ----------------------------------------------------
  // UPDATED: METHODS FOR THE DAILY/ALL-TIME INTERESTS
  // ----------------------------------------------------

  // NEW METHOD: Stream a list of all-time interests (returns QuerySnapshot)
  Stream<QuerySnapshot> getAllInterestsStream(String userId) {
    return _firestore
        .collection('interests')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // NEW METHOD: To delete a specific interest document
  Future<void> deleteInterest(String documentId) async {
    try {
      await _firestore.collection('interests').doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting interest: $e');
      rethrow;
    }
  }

  // **IMPORTANT FIX:** This method now returns a Stream<QuerySnapshot>
  Stream<QuerySnapshot> getDailyInterestsStream(String userId) {
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
        .snapshots(); // It now returns the raw QuerySnapshot
  }
}
