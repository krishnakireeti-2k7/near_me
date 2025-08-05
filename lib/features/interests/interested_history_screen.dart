// file: lib/features/interests/screens/interested_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/interests/widgets/interest_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestedHistoryScreen extends ConsumerWidget {
  const InterestedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔥 Interested History'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Today'), Tab(text: 'All-Time')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInterestList(
              stream: ProfileRepository(
                firestore: FirebaseFirestore.instance,
                auth: FirebaseAuth.instance,
              ).getDailyInterestsStream(userId),
            ),
            _buildInterestList(
              stream: ProfileRepository(
                firestore: FirebaseFirestore.instance,
                auth: FirebaseAuth.instance,
              ).getAllInterestsStream(userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestList({
    required Stream<List<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final interests = snapshot.data ?? [];

        if (interests.isEmpty) {
          return const Center(child: Text("No interests yet."));
        }

        return ListView.builder(
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            final fromUserId = interest['fromUserId'] ?? 'Unknown';
            final timestamp = (interest['timestamp'] as Timestamp).toDate();

            return InterestTile(fromUserId: fromUserId, timestamp: timestamp);
          },
        );
      },
    );
  }
}
