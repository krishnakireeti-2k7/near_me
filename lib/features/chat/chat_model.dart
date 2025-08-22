import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatBatchId;
  final String senderId;
  final String content;
  final Timestamp timestamp;

  ChatMessage({
    required this.id,
    required this.chatBatchId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatBatchId': chatBatchId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      chatBatchId: map['chatBatchId'] as String,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }
}

class ChatBatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final Timestamp startTimestamp;

  ChatBatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.startTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'startTimestamp': startTimestamp,
    };
  }

  factory ChatBatch.fromMap(Map<String, dynamic> map) {
    return ChatBatch(
      id: map['id'] as String,
      user1Id: map['user1Id'] as String,
      user2Id: map['user2Id'] as String,
      startTimestamp: map['timestamp'] as Timestamp,
    );
  }
}
