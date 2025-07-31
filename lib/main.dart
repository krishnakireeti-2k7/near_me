// file: main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/app/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// This is a top-level function to handle background messages.
// It must not be an anonymous function or a method on a class.
@pragma('vm:entry-point') // A must for background handlers
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're using other Firebase services in the background, such as Firestore,
  // make sure to call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Handling a background message ${message.messageId}');

  // You can optionally show a local notification here if needed,
  // but avoid full NotificationService initialization that relies on Riverpod Ref.
  // For example:
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');
  // const InitializationSettings initializationSettings =
  //     InitializationSettings(android: initializationSettingsAndroid);
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // if (message.notification != null) {
  //   flutterLocalNotificationsPlugin.show(
  //     0,
  //     message.notification!.title!,
  //     message.notification!.body!,
  //     const NotificationDetails(android: AndroidNotificationDetails('high_importance_channel', 'High Importance Notifications')),
  //   );
  // }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  // <--- CHANGE to ConsumerStatefulWidget
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState(); // <--- Create state
}

class _MyAppState extends ConsumerState<MyApp> {
  // <--- New State class
  @override
  void initState() {
    super.initState();
    // Initialize NotificationService here, where 'ref' is available and guaranteed to run once
    // Access it via the provider and then call initNotifications
    Future.microtask(() {
      // Use Future.microtask to ensure the build context is fully ready
      ref.read(notificationServiceProvider).initNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NearMe',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
