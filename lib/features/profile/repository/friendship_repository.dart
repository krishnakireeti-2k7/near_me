import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendshipRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  FriendshipRepository({required FirebaseFirestore firestore, required Ref ref})
    : _firestore = firestore,
      _ref = ref;

  Future<void> sendFriendRequest({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
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
      debugPrint('FriendshipRepository: Friend request sent: $friendshipId');

      // Increment totalFriendRequestsCount
      final recipientRef = _firestore.collection('users').doc(receiverId);
      try {
        await recipientRef.update({
          'totalFriendRequestsCount': FieldValue.increment(1),
        });
        debugPrint(
          'FriendshipRepository: Incremented totalFriendRequestsCount for user: $receiverId',
        );
      } catch (e) {
        debugPrint(
          'FriendshipRepository: Failed to update totalFriendRequestsCount, setting initial value: $e',
        );
        await recipientRef.set({
          'totalFriendRequestsCount': 1,
        }, SetOptions(merge: true));
      }

      // Send notification via OutgoingNotificationService
      final recipientDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = recipientDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        debugPrint(
          'FriendshipRepository: Sending friend request notification to: $receiverId, token: $fcmToken',
        );
        await _ref
            .read(outgoingNotificationServiceProvider)
            .sendNotification(
              recipientToken: fcmToken,
              title: 'New Friend Request!',
              body: '$senderName wants to be friends!',
              data: {'screen': 'notifications'},
            );
      } else {
        debugPrint('FriendshipRepository: No FCM token for user: $receiverId');
      }
    } catch (e) {
      debugPrint('FriendshipRepository: Error sending friend request: $e');
      rethrow;
    }
  }

  Future<void> acceptFriendRequest({
    required String friendshipId,
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
  }) async {
    try {
      final friendshipDoc = _firestore
          .collection('friendships')
          .doc(friendshipId);
      await friendshipDoc.update({
        'status': FriendshipStatus.accepted.name,
        'timestamp': Timestamp.now(),
      });

      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([otherUserId]),
        'totalFriendRequestsCount': FieldValue.increment(-1),
      });
      await _firestore.collection('users').doc(otherUserId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // Send notification via OutgoingNotificationService
      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      final fcmToken = otherUserDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        debugPrint(
          'FriendshipRepository: Sending accept notification to: $otherUserId, token: $fcmToken',
        );
        await _ref
            .read(outgoingNotificationServiceProvider)
            .sendNotification(
              recipientToken: fcmToken,
              title: 'Friend Request Accepted!',
              body: '$currentUserName is now your friend!',
              data: {'screen': 'friends'},
            );
      } else {
        debugPrint('FriendshipRepository: No FCM token for user: $otherUserId');
      }
    } catch (e) {
      debugPrint('FriendshipRepository: Error accepting friend request: $e');
      rethrow;
    }
  }

  Future<void> unfriend({
    required String user1Id,
    required String user2Id,
  }) async {
    try {
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
      debugPrint('FriendshipRepository: Unfriended: $friendshipId');
    } catch (e) {
      debugPrint('FriendshipRepository: Error unfriending: $e');
      rethrow;
    }
  }

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

  Stream<List<FriendshipModel>> getDailyPendingFriendRequestsStream(
    String currentUserId,
  ) {
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
        .where('user2Id', isEqualTo: currentUserId)
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
      final friendshipDoc = _firestore
          .collection('friendships')
          .doc(friendshipId);
      final friendship = await friendshipDoc.get();
      final receiverId = friendship.data()?['user2Id'] as String?;

      await friendshipDoc.delete();
      debugPrint('FriendshipRepository: Friend request deleted: $friendshipId');

      if (receiverId != null) {
        await _firestore.collection('users').doc(receiverId).update({
          'totalFriendRequestsCount': FieldValue.increment(-1),
        });
        debugPrint(
          'FriendshipRepository: Decremented totalFriendRequestsCount for user: $receiverId',
        );
      }
    } catch (e) {
      debugPrint('FriendshipRepository: Error deleting friend request: $e');
      rethrow;
    }
  }
}
