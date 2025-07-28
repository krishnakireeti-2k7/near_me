// file: lib/features/profile/presentation/edit_profile_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp and GeoPoint
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Ensure GoRouter is imported
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Import the reusable widgets
import 'package:near_me/widgets/profile_form.dart';
import 'package:near_me/widgets/profile_image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final tagsController = TextEditingController();
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();

  File? _pickedImageFile;
  String? _currentProfileImageUrl;

  bool isLoading = true;
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _getUserLocation();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    try {
      final userProfile = await ref.read(
        userProfileProvider(widget.userId).future,
      );

      if (userProfile != null) {
        nameController.text = userProfile.name;
        bioController.text = userProfile.shortBio ?? '';
        tagsController.text = userProfile.tags?.join(', ') ?? '';
        instagramController.text = userProfile.socialHandles['instagram'] ?? '';
        twitterController.text = userProfile.socialHandles['twitter'] ?? '';
        _currentProfileImageUrl = userProfile.profileImageUrl;

        _userLatitude = userProfile.location?.latitude;
        _userLongitude = userProfile.location?.longitude;
      } else {
        showFloatingSnackBar(context, "Profile not found for editing.");
        if (mounted) context.go('/map'); // Go back to map if profile not found
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
      showFloatingSnackBar(context, "Failed to load profile data.");
      if (mounted) context.go('/map'); // Go back to map on error
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint("Location permissions are denied or permanently denied.");
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      debugPrint("Location obtained: $_userLatitude, $_userLongitude");
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
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
        _pickedImageFile = File(pickedFile.path);
        _currentProfileImageUrl = null;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    tagsController.dispose();
    instagramController.dispose();
    twitterController.dispose();
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

    final profileRepo = ref.read(profileRepositoryProvider);

    String finalImageUrl = _currentProfileImageUrl ?? '';

    try {
      if (_pickedImageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}_profile.jpg');

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = storageRef.putFile(_pickedImageFile!, metadata);

        final snapshot = await uploadTask.whenComplete(() {});
        if (snapshot.state == TaskState.success) {
          finalImageUrl = await storageRef.getDownloadURL();
          print('✅ Upload successful. Image URL: $finalImageUrl');
        } else {
          debugPrint(
            '❌ Upload failed: TaskState = ${snapshot.state}. Retaining previous URL or using empty.',
          );
        }
      }

      final updatedProfile = UserProfileModel(
        uid: user.uid,
        name: nameController.text.trim(),
        tags:
            tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        profileImageUrl: finalImageUrl,
        socialHandles: {
          'instagram': instagramController.text.trim(),
          'twitter': twitterController.text.trim(),
        },
        location:
            (_userLatitude != null && _userLongitude != null)
                ? GeoPoint(_userLatitude!, _userLongitude!)
                : null,
        shortBio: bioController.text.trim(),
        lastActive: Timestamp.now(),
      );

      await profileRepo.createOrUpdateProfile(updatedProfile);

      ref.invalidate(userProfileProvider(user.uid));

      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile updated successfully!");
      context.go(
        '/map',
      ); // <--- CHANGED FROM context.pop() TO context.go('/map')
    } catch (e, stackTrace) {
      print('Error saving profile: $e');
      print('Stack Trace: $stackTrace');
      setState(() => isLoading = false);
      showFloatingSnackBar(
        context,
        "Failed to update profile. Please try again.",
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
          'Edit Your Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            context.go(
              '/map',
            ); // <--- CHANGED FROM Navigator.of(context).pop() TO context.go('/map')
          },
        ),
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
                        profileImage: _pickedImageFile,
                        initialImageUrl:
                            _pickedImageFile == null
                                ? _currentProfileImageUrl
                                : null,
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
