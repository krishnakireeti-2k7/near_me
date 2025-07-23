import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          Future.microtask(() => context.go('/login'));
        } else {
          final userProfile = ref.watch(userProfileProvider(user.uid));
          return userProfile.when(
            data: (profile) {
              if (profile == null) {
                Future.microtask(() => context.go('/create-profile'));
              } else {
                Future.microtask(() => context.go('/map'));
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
            loading:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) =>
                    Scaffold(body: Center(child: Text('Profile error: $e'))),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
    );
  }
}
