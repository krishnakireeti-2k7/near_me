// file: lib/features/interests/widgets/interest_tile.dart

import 'package:flutter/material.dart';

class InterestTile extends StatelessWidget {
  final String fromUserId;
  final DateTime timestamp;

  const InterestTile({
    super.key,
    required this.fromUserId,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        // You can load profile pic here using fromUserId if needed
        child: Text(fromUserId[0].toUpperCase()),
      ),
      title: Text('User ID: $fromUserId'),
      subtitle: Text('Time: ${timestamp.toLocal()}'),
    );
  }
}
