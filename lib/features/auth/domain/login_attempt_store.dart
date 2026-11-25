/// Kod [AuthException] kad je prijava odbijena jer je račun zaključan.
const String accountLockedCode = 'account-locked';

/// Stanje neuspjelih prijava za jedan e-mail.
class LoginAttemptRecord {
  const LoginAttemptRecord({required this.failures, this.lockedUntil});

  final int failures;

  /// Ako nije `null`, račun je zaključan do tog trenutka.
  final DateTime? lockedUntil;
}

/// Spremište brojača neuspjelih prijava.
///
/// Sučelje je asinkrono kako bi se kasnije mogla dodati trajna implementacija
/// (npr. `shared_preferences`) bez promjene [LockoutAuthService].
abstract interface class LoginAttemptStore {
  Future<LoginAttemptRecord?> read(String key);
  Future<void> write(String key, LoginAttemptRecord record);
  Future<void> clear(String key);
}

/// Čuva brojače u memoriji; ponovnim pokretanjem aplikacije se resetiraju.
class InMemoryLoginAttemptStore implements LoginAttemptStore {
  final Map<String, LoginAttemptRecord> _records = {};

  @override
  Future<LoginAttemptRecord?> read(String key) async => _records[key];

  @override
  Future<void> write(String key, LoginAttemptRecord record) async {
    _records[key] = record;
  }

  @override
  Future<void> clear(String key) async {
    _records.remove(key);
  }
}
