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

  Future<void> _translateErrors(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code, message: error.message);
    }
  }
}
