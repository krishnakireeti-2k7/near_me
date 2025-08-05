import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class AllInterestsScreen extends ConsumerWidget {
  const AllInterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInterestsAsync = ref.watch(allInterestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All-Time Interests')),
      body: allInterestsAsync.when(
        data: (interests) {
          if (interests.isEmpty) {
            return const Center(child: Text("No interests yet."));
          }

          return ListView.builder(
            itemCount: interests.length,
            itemBuilder: (context, index) {
              final interest = interests[index];
              final fromName = interest['fromName'] ?? 'Someone';
              final timestamp =
                  interest['timestamp']?.toDate().toString().substring(0, 16) ??
                  'Unknown time';

              return ListTile(
                leading: const Icon(Icons.whatshot, color: Colors.red),
                title: Text('$fromName hit Interested'),
                subtitle: Text(timestamp),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
