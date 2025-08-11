// file: lib/features/profile/repository/friendship_repository_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/services/notification_service.dart';

// Provides an instance of the FriendshipRepository
final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepository(
    firestore: FirebaseFirestore.instance,
    outgoingNotificationService: ref.read(outgoingNotificationServiceProvider),
  );
});

// A stream provider to get all pending friend requests for the current user.
final pendingFriendRequestsProvider = StreamProvider<List<FriendshipModel>>((
  ref,
) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser?.uid == null) {
    return const Stream.empty();
  }
  return ref
      .read(friendshipRepositoryProvider)
      .getPendingFriendRequestsStream(currentUser!.uid);
});

// ✅ NEW: A provider that gives you the count of pending friend requests.
final pendingFriendRequestsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(pendingFriendRequestsProvider)
      .when(
        data: (requests) => Stream.value(requests.length),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

// Provides a stream of the friendship status between the current user and another user.
final friendshipStatusStreamProvider =
    StreamProvider.family<FriendshipModel?, String>((ref, otherUserId) {
      final currentUserProfile =
          ref.watch(currentUserProfileStreamProvider).value;
      final currentUserId = currentUserProfile?.uid;

      if (currentUserId == null) {
        return Stream.value(null);
      }

      return ref
          .read(friendshipRepositoryProvider)
          .getFriendshipStatusStream(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
          );
    });
