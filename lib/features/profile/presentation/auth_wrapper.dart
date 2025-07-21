// main.dart or features/auth/presentation/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/auth/auth_view.dart';
import 'package:near_me/features/profile/presentation/create_profile_screen.dart'; // Replace with your screen
import 'package:near_me/features/auth/auth_controller.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const CreateProfileScreen(); // User is signed in
        } else {
          return const AuthView(); // User not signed in
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
