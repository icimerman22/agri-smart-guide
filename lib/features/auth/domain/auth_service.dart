abstract interface class AuthService {
  AuthUser? get currentUser;

  Future<void> register({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
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
