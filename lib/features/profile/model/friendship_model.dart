// file: lib/features/profile/model/friendship_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted, rejected, none }

class FriendshipModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String senderId;
  final FriendshipStatus status;
  final Timestamp timestamp;

  FriendshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.senderId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id, // ✅ FIXED: Changed to camelCase
      'user2Id': user2Id, // ✅ FIXED: Changed to camelCase
      'senderId': senderId, // ✅ FIXED: Changed to camelCase
      'status': status.name,
      'timestamp': timestamp,
    };
  }

  factory FriendshipModel.fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      id: map['id'] as String,
      user1Id: map['user1Id'] as String, // ✅ FIXED: Changed to camelCase
      user2Id: map['user2Id'] as String, // ✅ FIXED: Changed to camelCase
      senderId: map['senderId'] as String, // ✅ FIXED: Changed to camelCase
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendshipStatus.none,
      ),
      timestamp: map['timestamp'] as Timestamp,
    );
  }
}
