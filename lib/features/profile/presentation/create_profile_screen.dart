// lib/features/profile/presentation/create_profile_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp and GeoPoint
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart'; // Ensure this is updated in a later step
import 'package:geolocator/geolocator.dart'; // For location handling
import 'package:firebase_storage/firebase_storage.dart'; // For image upload
import 'package:image_picker/image_picker.dart'; // For picking images

// Import the new widgets
import 'package:near_me/widgets/profile_form.dart'; // Ensure this widget is updated
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
  // REMOVED: yearController and branchController as they are no longer in UserProfileModel
  final tagsController =
      TextEditingController(); // MODIFIED: Renamed from interestsController
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final bioController =
      TextEditingController(); // Renamed from shortBioController for consistency with model field 'shortBio'

  File? _profileImage;
  bool isLoading = false;
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // You might want to show a SnackBar or dialog here
      debugPrint("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // You might want to show a SnackBar or dialog here
        debugPrint("Location permissions are denied or permanently denied.");
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Request high accuracy
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      debugPrint("Location obtained: $_userLatitude, $_userLongitude");
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Handle potential errors like timeout
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image quality
      maxWidth: 800, // Max width for the image
      maxHeight: 800, // Max height for the image
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
    // yearController.dispose(); // REMOVED
    // branchController.dispose(); // REMOVED
    tagsController.dispose(); // MODIFIED
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

    final profileRepo = ref.read(
      profileRepositoryProvider,
    ); // Use userProfileRepositoryProvider

    // Non-nullable imageUrl
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
          print('✅ Upload successful. Image URL: $imageUrl');
        } else {
          // If upload fails, fallback to existing photoURL or empty string
          imageUrl = user.photoURL ?? '';
          debugPrint(
            '❌ Upload failed: TaskState = ${snapshot.state}. Falling back to default URL.',
          );
        }
      } else {
        imageUrl =
            user.photoURL ??
            ''; // Use existing Firebase user photo if no new image picked
      }

      final profile = UserProfileModel(
        uid: user.uid,
        name: nameController.text.trim(),
        // REMOVED: collegeYear and branch
        tags:
            tagsController
                .text // MODIFIED: Renamed from interests
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
            (_userLatitude != null && _userLongitude != null)
                ? GeoPoint(_userLatitude!, _userLongitude!)
                : null,
        shortBio:
            bioController.text
                .trim(), // Corrected to match model field 'shortBio'
        lastActive:
            Timestamp.now(), // NEW: Set lastActive upon profile creation
      );

      await profileRepo.createOrUpdateProfile(
        profile,
      ); // Ensure this method exists and correctly uses toMap()

      // Invalidate the provider so the map screen gets the updated profile immediately
      ref.invalidate(userProfileProvider(user.uid));

      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile created successfully!");
      GoRouter.of(
        context,
      ).go('/map'); // Navigate to map after successful creation
    } catch (e, stackTrace) {
      print('Error saving profile: $e');
      print('Stack Trace: $stackTrace');
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
                      // MODIFIED: Update ProfileForm parameters
                      ProfileForm(
                        formKey: _formKey,
                        nameController: nameController,
                        // REMOVED: yearController, branchController
                        bioController: bioController, // Pass the bioController
                        tagsController:
                            tagsController, // MODIFIED: Pass tagsController
                        instagramController: instagramController,
                        twitterController: twitterController,
                        onSubmit: _submitProfile,
                      ),
                      const SizedBox(height: 24), // Added some bottom padding
                    ],
                  ),
                ),
      ),
    );
  }
}
