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
  final yearController = TextEditingController();
  final branchController = TextEditingController();
  final interestsController = TextEditingController();
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final bioController = TextEditingController();

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
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
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
    yearController.dispose();
    branchController.dispose();
    interestsController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    bioController.dispose();
    super.dispose();
  }

 Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "User not authenticated.");
      return;
    }

    final profileRepo = ref.read(profileRepositoryProvider);

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
          throw Exception('❌ Upload failed: TaskState = ${snapshot.state}');
        }
      } else {
        imageUrl = user.photoURL ?? '';
      }

      final profile = UserProfileModel(
        uid: user.uid,
        name: nameController.text.trim(),
        collegeYear: yearController.text.trim(),
        branch: branchController.text.trim(),
        interests:
            interestsController.text
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
      );

      await profileRepo.createOrUpdateProfile(profile);

      ref.invalidate(userProfileProvider(user.uid));

      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile saved!");
      GoRouter.of(context).go('/map');
    } catch (e, stackTrace) {
      print('Error saving profile: $e');
      print('Stack Trace: $stackTrace');
      setState(() => isLoading = false);
      showFloatingSnackBar(
        context,
        "Failed to save profile. Check console for details.",
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
                        yearController: yearController,
                        branchController: branchController,
                        bioController: bioController,
                        interestsController: interestsController,
                        instagramController: instagramController,
                        twitterController: twitterController,
                        onSubmit: _submitProfile,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
