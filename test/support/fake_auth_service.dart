import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.currentUser});

  @override
  AuthUser? currentUser;

  AuthException? registerError;
  AuthException? signInError;
  AuthException? signOutError;
  Future<void>? registerGate;
  Future<void>? signInGate;
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
    if (registerGate != null) await registerGate;
    if (registerError != null) throw registerError!;
    currentUser = AuthUser(uid: 'test-user', email: email);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (signInGate != null) await signInGate;
    if (signInError != null) throw signInError!;
    currentUser = AuthUser(uid: 'test-user', email: email);
  }

  AuthException? changePasswordError;
  int changePasswordCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
    currentUser = null;
  }
}
