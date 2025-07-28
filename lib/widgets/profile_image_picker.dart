// lib/widgets/profile_image_picker.dart

import 'dart:io';
import 'package:flutter/material.dart';

class ProfileImagePicker extends StatelessWidget {
  final File? profileImage; // For a newly picked file
  final String? initialImageUrl; // For an existing network image URL
  final VoidCallback onPickImage;

  const ProfileImagePicker({
    super.key,
    this.profileImage,
    this.initialImageUrl, // New property
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    Widget? childIcon;

    if (profileImage != null) {
      // If a new image file is picked, use it
      backgroundImage = FileImage(profileImage!);
    } else if (initialImageUrl != null && initialImageUrl!.isNotEmpty) {
      // If no new image and an initial URL exists, use the network image
      backgroundImage = NetworkImage(initialImageUrl!);
    } else {
      // Otherwise, show the default person icon
      childIcon = Icon(Icons.person, color: Colors.grey[600], size: 60);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: backgroundImage,
            child: childIcon, // Display icon only if no image is present
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPickImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
