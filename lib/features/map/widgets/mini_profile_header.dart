// file: mini_profile_header.dart

import 'package:flutter/material.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';

class MiniProfileHeader extends StatelessWidget {
  final UserProfileModel user;
  final bool isCurrentUser;
  final String? imageUrlToShow;

  const MiniProfileHeader({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.imageUrlToShow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              imageUrlToShow != null ? NetworkImage(imageUrlToShow!) : null,
          child:
              imageUrlToShow == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCurrentUser)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                "${user.collegeYear} • ${user.branch}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (user.shortBio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.shortBio,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
