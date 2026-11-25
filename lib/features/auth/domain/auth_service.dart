abstract interface class AuthService {
  AuthUser? get currentUser;

  Future<void> register({required String email, required String password});
  Future<SignInResult> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut();

  Future<TotpEnrollmentStatus> totpEnrollmentStatus({bool refresh = false});
  Future<void> sendTotpVerificationEmail();
  Future<TotpEnrollment> beginTotpEnrollment({required String password});

  /// Changes the password of the signed-in user after confirming the current
  /// password (Firebase requires recent re-authentication for this).
  /// Returns false if the requested second factor was not confirmed.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required Future<void> Function(TotpVerifier verify) confirmTotp,
  });
}

typedef TotpVerifier = Future<void> Function(String code);

enum TotpEnrollmentStatus { emailUnverified, available, enabled }

final class TotpEnrollment {
  const TotpEnrollment({required this.setupKey, required this.verify});

  final String setupKey;
  final TotpVerifier verify;
}

sealed class SignInResult {
  const SignInResult();
}

final class SignedIn extends SignInResult {
  const SignedIn();
}

final class TotpSignInRequired extends SignInResult {
  const TotpSignInRequired(this.verify);

  final TotpVerifier verify;
}

class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

class AuthException implements Exception {
  const AuthException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
