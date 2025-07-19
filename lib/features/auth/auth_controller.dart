import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, User?>((
  ref,
) {
  final repo = AuthRepository();
  return AuthController(repo);
});

class AuthController extends StateNotifier<User?> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(_repo.currentUser);

  Future<void> signInWithGoogle() async {
    final user = await _repo.signInWithGoogle();
    state = user;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
  }
}
