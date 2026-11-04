import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.currentUser});

  @override
  AuthUser? currentUser;

  AuthException? registerError;
  AuthException? signInError;
  AuthException? signOutError;
  int registerCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    lastEmail = email;
    lastPassword = password;
    if (registerError != null) throw registerError!;
    currentUser = AuthUser(uid: 'test-user', email: email);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (signInError != null) throw signInError!;
    currentUser = AuthUser(uid: 'test-user', email: email);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
    currentUser = null;
  }
}
