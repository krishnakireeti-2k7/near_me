import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/app/router.dart';
import 'package:near_me/app/theme.dart'; // ✅ NEW: Import your theme file
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/firebase_options.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'NearMe',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: lightTheme, // ✅ ADD THIS LINE to apply the theme
      builder:
          (context, child) => FriendRequestNotificationHandler(
            child: InterestNotificationHandler(child: child!),
          ),
    );
  }
}

class InterestNotificationHandler extends ConsumerStatefulWidget {
  final Widget child;

  const InterestNotificationHandler({super.key, required this.child});

  @override
  ConsumerState<InterestNotificationHandler> createState() =>
      _InterestNotificationHandlerState();
}

class _InterestNotificationHandlerState
    extends ConsumerState<InterestNotificationHandler> {
  int? _previousTotalInterestsCount;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationServiceProvider).initNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<
      AsyncValue<UserProfileModel?>
    >(currentUserProfileStreamProvider, (previous, next) async {
      final newProfile = next.value;
      debugPrint(
        'InterestNotificationHandler: Profile update: ${next.value?.toMap()}',
      );
      if (newProfile != null && newProfile.uid.isNotEmpty) {
        if (_previousTotalInterestsCount == null) {
          _previousTotalInterestsCount = newProfile.totalInterestsCount;
          debugPrint(
            'InterestNotificationHandler: Initial totalInterestsCount: $_previousTotalInterestsCount',
          );
        }

        if (newProfile.totalInterestsCount >
            (_previousTotalInterestsCount ?? 0)) {
          if (context.mounted) {
            showFloatingSnackBar(
              context,
              'Someone is interested in you!',
              backgroundColor: Colors.amber.shade700,
              textColor: Colors.white,
              leadingIcon: Icons.whatshot,
              duration: const Duration(seconds: 3),
              position: SnackBarPosition.top,
            );
          }

          await ref
              .read(localInterestsServiceProvider)
              .incrementDailyInterestsCount();
          debugPrint(
            'InterestNotificationHandler: Local daily interests count incremented!',
          );
        }

        _previousTotalInterestsCount = newProfile.totalInterestsCount;
      } else if (newProfile == null && _previousTotalInterestsCount != null) {
        _previousTotalInterestsCount = null;
        debugPrint(
          'InterestNotificationHandler: User logged out or profile became null, resetting previous count.',
        );
      }
    });

    return widget.child;
  }
}

class FriendRequestNotificationHandler extends ConsumerStatefulWidget {
  final Widget child;

  const FriendRequestNotificationHandler({super.key, required this.child});

  @override
  ConsumerState<FriendRequestNotificationHandler> createState() =>
      _FriendRequestNotificationHandlerState();
}

class _FriendRequestNotificationHandlerState
    extends ConsumerState<FriendRequestNotificationHandler> {
  int? _previousTotalFriendRequestsCount;

  @override
  Widget build(BuildContext context) {
    ref.listen<
      AsyncValue<UserProfileModel?>
    >(currentUserProfileStreamProvider, (previous, next) async {
      debugPrint(
        'FriendRequestNotificationHandler: Profile update: ${next.value?.toMap()}',
      );
      if (next.hasError) {
        debugPrint('FriendRequestNotificationHandler: Error: ${next.error}');
        return;
      }

      final newProfile = next.value;
      if (newProfile != null && newProfile.uid.isNotEmpty) {
        if (_previousTotalFriendRequestsCount == null) {
          _previousTotalFriendRequestsCount =
              newProfile.totalFriendRequestsCount;
          debugPrint(
            'FriendRequestNotificationHandler: Initial totalFriendRequestsCount: $_previousTotalFriendRequestsCount',
          );
        }

        if (newProfile.totalFriendRequestsCount >
            (_previousTotalFriendRequestsCount ?? 0)) {
          if (context.mounted) {
            showFloatingSnackBar(
              context,
              'You have a new friend request!',
              backgroundColor: Colors.blue.shade700,
              textColor: Colors.white,
              leadingIcon: Icons.person_add,
              duration: const Duration(seconds: 3),
              position: SnackBarPosition.top,
            );
            debugPrint(
              'FriendRequestNotificationHandler: Friend request snackbar shown!',
            );
          }
        }

        _previousTotalFriendRequestsCount = newProfile.totalFriendRequestsCount;
      } else if (newProfile == null &&
          _previousTotalFriendRequestsCount != null) {
        _previousTotalFriendRequestsCount = null;
        debugPrint(
          'FriendRequestNotificationHandler: User logged out or profile became null, resetting previous count.',
        );
      }
    });

    return widget.child;
  }
}
