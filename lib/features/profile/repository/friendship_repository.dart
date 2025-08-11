// file: lib/features/profile/repository/friendship_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/services/notification_service.dart';

class FriendshipRepository {
  final FirebaseFirestore _firestore;
  // ✅ NEW: Add the outgoing notification service dependency
  final OutgoingNotificationService _outgoingNotificationService;

  FriendshipRepository({
    required FirebaseFirestore firestore,
    // ✅ NEW: Add to the constructor
    required OutgoingNotificationService outgoingNotificationService,
  }) : _firestore = firestore,
       _outgoingNotificationService = outgoingNotificationService;

  // ✅ NEW: Helper method to send the friend request notification
  Future<void> _sendRequestNotification(
    String senderName,
    String receiverId,
  ) async {
    final receiverProfile =
        await _firestore.collection('users').doc(receiverId).get();
    final receiverFcmToken = receiverProfile.data()?['fcmToken'] as String?;

    if (receiverFcmToken != null) {
      await _outgoingNotificationService.sendNotification(
        recipientToken: receiverFcmToken,
        title: 'New Friend Request!',
        body: '$senderName wants to be friends!',
        data: {'screen': 'notifications'},
      );
    }
  }

  // ✅ NEW: Helper method to send the friend accepted notification
  Future<void> _sendAcceptNotification(
    String accepterName,
    String otherUserId,
  ) async {
    final otherUserProfile =
        await _firestore.collection('users').doc(otherUserId).get();
    final otherUserFcmToken = otherUserProfile.data()?['fcmToken'] as String?;

    if (otherUserFcmToken != null) {
      await _outgoingNotificationService.sendNotification(
        recipientToken: otherUserFcmToken,
        title: 'Friend Request Accepted!',
        body: '$accepterName is now your friend!',
        data: {'screen': 'friends'},
      );
    }
  }

  // Sends a friend request by creating a new document in the 'friendships' collection.
  Future<void> sendFriendRequest({
    required String senderId,
    // ✅ NEW: Add senderName for the notification body
    required String senderName,
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

    // ✅ NEW: Call the notification helper method
    await _sendRequestNotification(senderName, receiverId);
  }

  // Accepts a friend request and updates the 'friends' list for both users.
  Future<void> acceptFriendRequest({
    required String friendshipId,
    required String currentUserId,
    required String otherUserId,
    // ✅ NEW: Add currentUserName for the notification body
    required String currentUserName,
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

    // ✅ NEW: Call the notification helper method
    await _sendAcceptNotification(currentUserName, otherUserId);
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

  Stream<List<FriendshipModel>> getPendingFriendRequestsStream(
    String currentUserId,
  ) {
    return _firestore
        .collection('friendships')
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                return (data['user1Id'] == currentUserId ||
                        data['user2Id'] == currentUserId) &&
                    data['senderId'] != currentUserId;
              })
              .map((doc) => FriendshipModel.fromMap(doc.data()))
              .toList();
        });
  }

  // ✅ NEW METHOD: Gets the count of pending friend requests from today.
  Stream<List<FriendshipModel>> getDailyPendingFriendRequestsStream(
    String currentUserId,
  ) {
    // Get the timestamp for the start of today
    final startOfToday = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

    return _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: currentUserId) // 👈 This is the key change
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .where('timestamp', isGreaterThanOrEqualTo: startOfTodayTimestamp)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendshipModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> deleteFriendRequest(String friendshipId) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).delete();
    } catch (e) {
      debugPrint('Error deleting friend request: $e');
      rethrow;
    }
  }
}
