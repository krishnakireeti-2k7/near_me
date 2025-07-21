import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/presentation/auth_wrapper.dart';
import 'features/auth/auth_view.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearMe',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), 
    );
  }
}


class NearMeApp extends StatelessWidget {
  const NearMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearMe',
      //theme: ThemeData(
      //),
      home: const AuthView(),
    );
  }
}
