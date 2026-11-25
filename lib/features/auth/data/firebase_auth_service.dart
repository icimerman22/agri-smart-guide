import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  }) => _translateErrors(() async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const SignedIn();
    } on FirebaseAuthMultiFactorException catch (error) {
      return TotpSignInRequired(_totpVerifier(error.resolver));
    }
  });

  @override
  Future<void> signOut() => _translateErrors(_auth.signOut);

  @override
  Future<TotpEnrollmentStatus> totpEnrollmentStatus({bool refresh = false}) =>
      _translateErrors(() async {
        var user = _signedInUser();
        if (refresh) {
          await user.reload();
          _requireCurrentUser(user.uid);
          user = _signedInUser();
        }
        if (await _hasTotp(user)) return TotpEnrollmentStatus.enabled;
        return user.emailVerified
            ? TotpEnrollmentStatus.available
            : TotpEnrollmentStatus.emailUnverified;
      });

  @override
  Future<void> sendTotpVerificationEmail() =>
      _translateErrors(() => _signedInUser().sendEmailVerification());

  @override
  Future<TotpEnrollment> beginTotpEnrollment({required String password}) =>
      _translateErrors(() async {
        final user = _signedInUser();
        final email = user.email;
        if (email == null || !user.emailVerified) {
          throw const AuthException('unverified-email');
        }
        if (await _hasTotp(user)) {
          throw const AuthException('second-factor-already-in-use');
        }

        _requireCurrentUser(user.uid);
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        _requireCurrentUser(user.uid);
        final session = await user.multiFactor.getSession();
        final secret = await TotpMultiFactorGenerator.generateSecret(session);
        _requireCurrentUser(user.uid);

        return TotpEnrollment(
          setupKey: secret.secretKey,
          verify: (code) => _translateErrors(() async {
            final deadline = secret.enrollmentCompletionDeadline;
            if (deadline != null && !DateTime.now().isBefore(deadline)) {
              throw const AuthException('session-expired');
            }
            _requireCurrentUser(user.uid);
            final assertion =
                await TotpMultiFactorGenerator.getAssertionForEnrollment(
                  secret,
                  code,
                );
            _requireCurrentUser(user.uid);
            await user.multiFactor.enroll(
              assertion,
              displayName: 'Agri Smart Guide',
            );
          }),
        );
      });

  User _signedInUser() {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('no-current-user');
    return user;
  }

  Future<bool> _hasTotp(User user) async {
    final factors = await user.multiFactor.getEnrolledFactors();
    return factors.whereType<TotpMultiFactorInfo>().isNotEmpty;
  }

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

  @override
  Future<bool> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId:
          '1079203745813-72m8650jfg4jcgdvkr7k99rte1bh8c4e.apps.googleusercontent.com',
    );

    try {
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _translateErrors(() async {
        await _auth.signInWithCredential(credential);
      });
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthException(
        e.code.name,
        message: '${e.code.name}: ${e.description}',
      );
    }
  }
}
