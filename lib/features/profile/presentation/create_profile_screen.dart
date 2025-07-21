import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/widgets/custom_text_field.dart';
import 'package:geolocator/geolocator.dart';

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
      profileImageUrl: user.photoURL ?? '',
      socialHandles: {
        'instagram': instagramController.text.trim(),
        'twitter': twitterController.text.trim(),
      },
      location:
          (_userLatitude != null && _userLongitude != null)
              ? GeoPoint(_userLatitude!, _userLongitude!)
              : null,
    );

    try {
      await profileRepo.createOrUpdateProfile(profile);
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Profile saved!");
    } catch (e) {
      setState(() => isLoading = false);
      showFloatingSnackBar(context, "Failed to save profile.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Your Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tell us about yourself to connect with others.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: nameController,
                          label: 'Name',
                          requiredField: true,
                        ),
                        CustomTextField(
                          controller: yearController,
                          label: 'College Year',
                          hint: 'e.g. 1st, 2nd',
                        ),
                        CustomTextField(
                          controller: branchController,
                          label: 'Branch / Department',
                        ),
                        CustomTextField(
                          controller: bioController,
                          label: 'Short Bio',
                          hint: 'e.g. I love coding and startups!',
                        ),
                        CustomTextField(
                          controller: interestsController,
                          label: 'Interests',
                          hint: 'e.g. Flutter, Web Dev (comma separated)',
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 32),
                        Text(
                          'Social Links (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: instagramController,
                          label: 'Instagram',
                          hint: '@yourhandle',
                          isSocial: true,
                          prefixIcon: Icons.alternate_email,
                        ),
                        CustomTextField(
                          controller: twitterController,
                          label: 'Twitter',
                          hint: '@yourhandle',
                          isSocial: true,
                          prefixIcon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _submitProfile,
                            child: const Text(
                              'Save & Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}