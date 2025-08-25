// file: lib/features/chat/repository/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/chat/chat_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository_provider.dart';
import 'package:uuid/uuid.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  ChatRepository({required FirebaseFirestore firestore, required Ref ref})
    : _firestore = firestore,
      _ref = ref;

  Future<bool> _isFriend(String currentUserId, String otherUserId) async {
    final friendshipRepo = _ref.read(friendshipRepositoryProvider);
    final snapshot =
        await friendshipRepo
            .getFriendshipStatusStream(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
            )
            .first;
    return snapshot?.status == FriendshipStatus.accepted;
  }

  // ✅ UPDATED METHOD FOR TESTING
  Future<String?> _getOrCreateChatBatchId(
    String user1Id,
    String user2Id,
  ) async {
    final userIds = [user1Id, user2Id]..sort();
    final chatBatchId = userIds.join('_');
    final chatBatchRef = _firestore.collection('chat_batches').doc(chatBatchId);

    final chatBatchDoc = await chatBatchRef.get();

    if (chatBatchDoc.exists) {
      final Timestamp startTimestamp = chatBatchDoc.data()?['startTimestamp'];
      // ✅ Test expiration time of 1 minute
      final chatEndTime = startTimestamp.toDate().add(
        const Duration(hours: 12),
      );
      if (DateTime.now().isAfter(chatEndTime)) {
        // If expired, delete the old chat and create a new one
        await chatBatchRef.delete();
        debugPrint('ChatRepository: Deleted expired chat batch: $chatBatchId');
        return _getOrCreateChatBatchId(
          user1Id,
          user2Id,
        ); // Recurse to create new
      }
      debugPrint('ChatRepository: Found existing chat batch: $chatBatchId');
      return chatBatchId;
    }

    // If the document does not exist, create it
    final newBatch = ChatBatch(
      id: chatBatchId,
      user1Id: userIds[0],
      user2Id: userIds[1],
      startTimestamp: Timestamp.now(),
    );

    await chatBatchRef.set(newBatch.toMap());
    debugPrint('ChatRepository: Created new chat batch: $chatBatchId');
    return chatBatchId;
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      debugPrint(
        'ChatRepository: Sending message from $senderId to $receiverId',
      );
      if (!await _isFriend(senderId, receiverId)) {
        debugPrint('ChatRepository: Users are not friends');
        throw Exception('Users are not friends');
      }

      final chatBatchId = await _getOrCreateChatBatchId(senderId, receiverId);
      if (chatBatchId == null) {
        debugPrint('ChatRepository: Failed to get or create chat batch');
        throw Exception('Failed to get or create chat batch');
      }

      final messageId = const Uuid().v4();
      final message = ChatMessage(
        id: messageId,
        chatBatchId: chatBatchId,
        senderId: senderId,
        content: content,
        timestamp: Timestamp.now(),
      );

      await _firestore
          .collection('chat_batches')
          .doc(chatBatchId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
      debugPrint('ChatRepository: Message sent: $messageId');
    } catch (e) {
      debugPrint('ChatRepository: Error sending message: $e');
      rethrow;
    }
  }

  Stream<List<ChatMessage>> getMessages(
    String currentUserId,
    String otherUserId,
  ) {
    final userIds = [currentUserId, otherUserId]..sort();
    final chatBatchId = userIds.join('_');
    return _firestore
        .collection('chat_batches')
        .doc(chatBatchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromMap(doc.data()))
                  .toList(),
        );
  }

  Stream<Timestamp?> getChatBatchStartTime(
    String currentUserId,
    String otherUserId,
  ) {
    final userIds = [currentUserId, otherUserId]..sort();
    final chatBatchId = userIds.join('_');
    return _firestore
        .collection('chat_batches')
        .doc(chatBatchId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['startTimestamp'] as Timestamp?);
  }
}
