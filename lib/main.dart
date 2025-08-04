// file: main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/app/app.dart';
import 'package:near_me/app/router.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/firebase_options.dart';
import 'package:near_me/services/local_interests_service.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:near_me/services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize and activate App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
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
    final authState = ref.watch(authStateProvider);

    ref.listen<AsyncValue<UserProfileModel?>>(
      currentUserProfileStreamProvider,
      (previous, next) async {
        final newProfile = next.value;

        if (newProfile != null && newProfile.uid.isNotEmpty) {
          if (_previousTotalInterestsCount == null) {
            _previousTotalInterestsCount = newProfile.totalInterestsCount;
            print('Initial totalInterestsCount: $_previousTotalInterestsCount');
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
            print('Local daily interests count incremented!');
          }

          _previousTotalInterestsCount = newProfile.totalInterestsCount;
        } else if (newProfile == null && _previousTotalInterestsCount != null) {
          _previousTotalInterestsCount = null;
          print(
            'User logged out or profile became null, resetting previous count.',
          );
        }
      },
    );

    return MaterialApp.router(
      title: 'NearMe',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
