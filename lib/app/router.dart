import 'package:go_router/go_router.dart';
import 'package:near_me/features/auth/auth_view.dart';
import 'package:near_me/features/profile/presentation/create_profile_screen.dart';
import 'package:near_me/features/map/presentation/map_screen.dart';
import 'package:near_me/features/profile/presentation/auth_wrapper.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
    GoRoute(
      path: '/login',
      builder:
          (context, state) => const AuthView(), // 👈 your actual login screen
    ),
    GoRoute(
      path: '/create-profile',
      builder: (context, state) => const CreateProfileScreen(),
    ),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
  ],
);
