abstract interface class AuthService {
  AuthUser? get currentUser;

  Future<void> register({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();

  /// Changes the password of the signed-in user after confirming the current
  /// password (Firebase requires recent re-authentication for this).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
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
