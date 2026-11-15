import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AuthUser(uid: user.uid, email: user.email);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _translateErrors(() async {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _translateErrors(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    });
  }

  @override
  Future<void> signOut() => _translateErrors(_auth.signOut);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException('no-current-user');
    }

    await _translateErrors(() async {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    });
  }

  Future<void> _translateErrors(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code, message: error.message);
    }
  }
}
