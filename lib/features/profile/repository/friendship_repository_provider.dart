import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/model/friendship_model.dart';
import 'package:near_me/features/profile/repository/friendship_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepository(firestore: FirebaseFirestore.instance, ref: ref);
});

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

final pendingFriendRequestsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(pendingFriendRequestsProvider)
      .when(
        data: (requests) => Stream.value(requests.length),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

final dailyFriendRequestsCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser == null) {
    return const Stream.empty();
  }

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  return FirebaseFirestore.instance
      .collection('friendships')
      .where('user2Id', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: FriendshipStatus.pending.name)
      .where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
      )
      .snapshots()
      .map((snapshot) => snapshot.size);
});

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
