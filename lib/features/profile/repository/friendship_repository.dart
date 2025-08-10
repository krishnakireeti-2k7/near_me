// file: lib/features/profile/repository/friendship_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:near_me/features/profile/model/friendship_model.dart';

class FriendshipRepository {
  final FirebaseFirestore _firestore;

  FriendshipRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  // Sends a friend request by creating a new document in the 'friendships' collection.
  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final userIds = [senderId, receiverId]..sort();
    final friendshipId = userIds.join('_');

    final friendshipDoc = _firestore
        .collection('friendships')
        .doc(friendshipId);

    final newFriendship = FriendshipModel(
      id: friendshipId,
      user1Id: userIds[0],
      user2Id: userIds[1],
      senderId: senderId,
      status: FriendshipStatus.pending,
      timestamp: Timestamp.now(),
    );

    await friendshipDoc.set(newFriendship.toMap());
  }

  // Accepts a friend request and updates the 'friends' list for both users.
  Future<void> acceptFriendRequest({
    required String friendshipId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final friendshipDoc = _firestore
        .collection('friendships')
        .doc(friendshipId);
    await friendshipDoc.update({
      'status': FriendshipStatus.accepted.name,
      'timestamp': Timestamp.now(),
    });

    // Add each user's UID to the other's friends list
    await _firestore.collection('users').doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([otherUserId]),
    });
    await _firestore.collection('users').doc(otherUserId).update({
      'friends': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // Unfriends a user by deleting the friendship document and updating friends lists.
  Future<void> unfriend({
    required String user1Id,
    required String user2Id,
  }) async {
    final userIds = [user1Id, user2Id]..sort();
    final friendshipId = userIds.join('_');
    final friendshipDoc = _firestore
        .collection('friendships')
        .doc(friendshipId);

    await friendshipDoc.delete();

    // Remove each user's UID from the other's friends list
    await _firestore.collection('users').doc(user1Id).update({
      'friends': FieldValue.arrayRemove([user2Id]),
    });
    await _firestore.collection('users').doc(user2Id).update({
      'friends': FieldValue.arrayRemove([user1Id]),
    });
  }

  // Gets the friendship status between two users.
  Stream<FriendshipModel?> getFriendshipStatusStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    final userIds = [currentUserId, otherUserId]..sort();
    final friendshipId = userIds.join('_');

    return _firestore
        .collection('friendships')
        .doc(friendshipId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return FriendshipModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  // ✅ FIXED: Adds the method to get a stream of pending friend requests.
  Stream<List<FriendshipModel>> getPendingFriendRequestsStream(
    String currentUserId,
  ) {
    return _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: currentUserId) // Corrected field name here
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendshipModel.fromMap(doc.data()))
              .toList();
        });
  }

  // ✅ NEW METHOD: Deletes a specific friend request document from Firestore.
  Future<void> deleteFriendRequest(String friendshipId) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).delete();
    } catch (e) {
      debugPrint('Error deleting friend request: $e');
      rethrow;
    }
  }
}
