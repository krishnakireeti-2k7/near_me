import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

class MiniProfileCard extends StatelessWidget {
  final UserProfileModel user;

  const MiniProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text("${user.collegeYear} • ${user.branch}"),
          SizedBox(height: 8),
          Text(user.interests.join(', ')),
          SizedBox(height: 8),
          if ((user.socialHandles['instagram'] ?? '').isNotEmpty)
            Text("Instagram: ${user.socialHandles['instagram']}"),
          if ((user.socialHandles['twitter'] ?? '').isNotEmpty)
            Text("Twitter: ${user.socialHandles['twitter']}"),
        ],
      ),
    );
  }
}
