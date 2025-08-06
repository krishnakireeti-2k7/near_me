// lib/features/profile/presentation/create_profile_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Import the new LocationService
import 'package:near_me/services/location_service.dart';

// Import the new widgets
import 'package:near_me/widgets/profile_form.dart';
import 'package:near_me/widgets/profile_image_picker.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final tagsController = TextEditingController();
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final bioController = TextEditingController();

  File? _profileImage;
  bool isLoading = false;

  // REMOVED: _userLatitude and _userLongitude are no longer needed as state variables.
  // The location will be fetched directly in the _submitProfile method.

  @override
  void initState() {
    super.initState();
    // REMOVED: _getUserLocation() call from initState.
    // The location is now fetched on demand during profile submission.
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    tagsController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      showFloatingSnackBar(
        context,
        "Please fill all required fields correctly.",
      );
      return;
    }

    setState(() => isLoading = true);

    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "User not authenticated.");
      return;
    }

    // NEW: Fetch user location here, right before submitting the profile.
    Position? userLocation;
    try {
      userLocation =
          await ref.read(locationServiceProvider).getCurrentLocation();
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Show an error to the user if location permission is denied
      if (context.mounted) {
        showFloatingSnackBar(
          context,
          "Please enable location services to create your profile.",
        );
      }
      setState(() => isLoading = false);
      return;
    }

    final profileRepo = ref.read(profileRepositoryProvider);

    late String imageUrl;

    try {
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}_profile.jpg');

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = storageRef.putFile(_profileImage!, metadata);
        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state == TaskState.success) {
          imageUrl = await storageRef.getDownloadURL();
          debugPrint('✅ Upload successful. Image URL: $imageUrl');
        } else {
          imageUrl = user.photoURL ?? '';
          debugPrint(
            '❌ Upload failed: TaskState = ${snapshot.state}. Falling back to default URL.',
          );
        }
      } else {
        imageUrl = user.photoURL ?? '';
      }

      final profile = UserProfileModel(
        uid: user.uid,
        name: nameController.text.trim(),
        tags:
            tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        profileImageUrl: imageUrl,
        socialHandles: {
          'instagram': instagramController.text.trim(),
          'twitter': twitterController.text.trim(),
        },
        location:
            userLocation != null
                ? GeoPoint(userLocation.latitude, userLocation.longitude)
                : null,
        shortBio: bioController.text.trim(),
        lastActive: Timestamp.now(),
      );

      await profileRepo.createOrUpdateProfile(profile);

      ref.invalidate(userProfileProvider(user.uid));

      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile created successfully!");
      GoRouter.of(context).go('/map');
    } catch (e, stackTrace) {
      debugPrint('Error saving profile: $e');
      debugPrint('Stack Trace: $stackTrace');
      setState(() => isLoading = false);
      showFloatingSnackBar(
        context,
        "Failed to save profile. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Your Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ProfileImagePicker(
                        profileImage: _profileImage,
                        onPickImage: _pickImage,
                      ),
                      const SizedBox(height: 32),
                      ProfileForm(
                        formKey: _formKey,
                        nameController: nameController,
                        bioController: bioController,
                        tagsController: tagsController,
                        instagramController: instagramController,
                        twitterController: twitterController,
                        onSubmit: _submitProfile,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }
}
