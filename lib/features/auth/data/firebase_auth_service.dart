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
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const SignedIn();
    } on FirebaseAuthMultiFactorException catch (error) {
      final verify = _totpVerifier(error.resolver);
      return TotpSignInRequired((code) async {
        await verify(code);
      });
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code, message: error.message);
    }
  }

  @override
  Future<void> signOut() => _translateErrors(_auth.signOut);

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required Future<void> Function(TotpVerifier verify) confirmTotp,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException('no-current-user');
    }

    return _translateErrors(() async {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthMultiFactorException catch (error) {
        final verify = _totpVerifier(error.resolver);
        var confirmed = false;
        await confirmTotp((code) async {
          _requireCurrentUser(user.uid);
          final result = await verify(code);
          if (result.user?.uid != user.uid) {
            throw const AuthException('auth-user-changed');
          }
          confirmed = true;
        });
        if (!confirmed) return false;
      }

      _requireCurrentUser(user.uid);
      await user.updatePassword(newPassword);
      return true;
    });
  }

  void _requireCurrentUser(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw const AuthException('auth-user-changed');
    }
  }

  Future<UserCredential> Function(String code) _totpVerifier(
    MultiFactorResolver resolver,
  ) {
    final factor = resolver.hints.whereType<TotpMultiFactorInfo>().firstOrNull;
    if (factor == null) {
      throw const AuthException(
        'unsupported-second-factor',
        message: 'Ovaj drugi faktor prijave nije podržan.',
      );
    }

    return (code) => _translateErrors(() async {
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
        factor.uid,
        code,
      );
      return resolver.resolveSignIn(assertion);
    });
  }

  Future<T> _translateErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code, message: error.message);
    }
  }
}
