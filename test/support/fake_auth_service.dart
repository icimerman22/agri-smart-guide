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
  Future<void> Function(String code)? signInTotp;
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
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (signInGate != null) await signInGate;
    if (signInError != null) throw signInError!;
    final verifyTotp = signInTotp;
    if (verifyTotp != null) {
      return TotpSignInRequired((code) async {
        await verifyTotp(code);
        currentUser = AuthUser(uid: 'test-user', email: email);
      });
    }
    currentUser = AuthUser(uid: 'test-user', email: email);
    return const SignedIn();
  }

  AuthException? changePasswordError;
  Future<void> Function(String code)? changePasswordTotp;
  int changePasswordCalls = 0;
  int passwordUpdates = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required Future<void> Function(TotpVerifier verify) confirmTotp,
  }) async {
    changePasswordCalls++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    if (changePasswordError != null) throw changePasswordError!;
    final verify = changePasswordTotp;
    if (verify != null) {
      var confirmed = false;
      await confirmTotp((code) async {
        await verify(code);
        confirmed = true;
      });
      if (!confirmed) return false;
    }
    passwordUpdates++;
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
    currentUser = null;
  }
}
