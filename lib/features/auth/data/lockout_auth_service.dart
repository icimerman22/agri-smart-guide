import '../domain/auth_service.dart';
import '../domain/login_attempt_store.dart';

/// Dekorator oko [AuthService] koji privremeno zaključava prijavu za e-mail
/// nakon [maxAttempts] uzastopnih neuspjelih pokušaja.
///
/// Zaštita je na strani klijenta (može se zaobići reinstalacijom); prava
/// zaštita bila bi na poslužitelju. Firebase uz to ima vlastiti
/// `too-many-requests`.
class LockoutAuthService implements AuthService {
  LockoutAuthService(
    this._inner, {
    LoginAttemptStore? store,
    DateTime Function()? now,
    this.maxAttempts = 5,
    this.lockDuration = const Duration(minutes: 15),
  }) : _store = store ?? InMemoryLoginAttemptStore(),
       _now = now ?? DateTime.now;

  static const String lockedCode = accountLockedCode;

  /// Samo ovi kodovi znače pogrešne podatke za prijavu; ostali (npr. mreža)
  /// se ne broje.
  static const Set<String> _countedCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
  };

  final AuthService _inner;
  final LoginAttemptStore _store;
  final DateTime Function() _now;
  final int maxAttempts;
  final Duration lockDuration;

  @override
  AuthUser? get currentUser => _inner.currentUser;

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    var record = await _store.read(key);

    final lockedUntil = record?.lockedUntil;
    if (lockedUntil != null) {
      if (_now().isBefore(lockedUntil)) {
        throw const AuthException(lockedCode);
      }
      await _store.clear(key);
      record = null;
    }

    final SignInResult result;
    try {
      result = await _inner.signIn(email: email, password: password);
    } on AuthException catch (error) {
      if (!_countedCodes.contains(error.code)) rethrow;

      final failures = (record?.failures ?? 0) + 1;
      if (failures >= maxAttempts) {
        await _store.write(
          key,
          LoginAttemptRecord(
            failures: failures,
            lockedUntil: _now().add(lockDuration),
          ),
        );
        throw const AuthException(lockedCode);
      }
      await _store.write(key, LoginAttemptRecord(failures: failures));
      rethrow;
    }

    // Lozinka je točna (i kad slijedi još TOTP korak), pa se brojač briše.
    await _store.clear(key);
    return result;
  }

  @override
  Future<bool> signInWithGoogle() => _inner.signInWithGoogle();

  @override
  Future<void> register({required String email, required String password}) =>
      _inner.register(email: email, password: password);

  @override
  Future<void> signOut() => _inner.signOut();

  @override
  Future<TotpEnrollmentStatus> totpEnrollmentStatus({bool refresh = false}) =>
      _inner.totpEnrollmentStatus(refresh: refresh);

  @override
  Future<void> sendTotpVerificationEmail() =>
      _inner.sendTotpVerificationEmail();

  @override
  Future<TotpEnrollment> beginTotpEnrollment({required String password}) =>
      _inner.beginTotpEnrollment(password: password);

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required Future<void> Function(TotpVerifier verify) confirmTotp,
  }) => _inner.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
    confirmTotp: confirmTotp,
  );
}
