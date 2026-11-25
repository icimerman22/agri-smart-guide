import 'package:agri_smart_guide/features/auth/data/lockout_auth_service.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/domain/login_attempt_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_service.dart';

void main() {
  const email = 'ana@opg.hr';
  const wrongPassword = 'pogresna';
  const correctPassword = 'tocna123';

  late FakeAuthService inner;
  late DateTime now;
  late LockoutAuthService service;

  setUp(() {
    inner = FakeAuthService();
    now = DateTime(2026, 11, 25, 12);
    service = LockoutAuthService(
      inner,
      store: InMemoryLoginAttemptStore(),
      now: () => now,
    );
  });

  Future<void> failSignIn(int times) async {
    inner.signInError = const AuthException('invalid-credential');
    for (var i = 0; i < times; i++) {
      try {
        await service.signIn(email: email, password: wrongPassword);
      } on AuthException {
        // Očekivano: pogrešna lozinka.
      }
    }
  }

  Matcher throwsAuthCode(String code) => throwsA(
    isA<AuthException>().having((e) => e.code, 'code', code),
  );

  test('4 neuspjela pokušaja ne zaključavaju račun', () async {
    await failSignIn(4);

    inner.signInError = null;
    await service.signIn(email: email, password: correctPassword);

    expect(inner.currentUser?.email, email);
  });

  test('peti neuspjeli pokušaj zaključava račun', () async {
    await failSignIn(4);

    expect(
      service.signIn(email: email, password: wrongPassword),
      throwsAuthCode(LockoutAuthService.lockedCode),
    );
  });

  test('zaključan račun odbija i točnu lozinku bez poziva Firebasea', () async {
    await failSignIn(5);
    final callsBefore = inner.signInCalls;

    inner.signInError = null;
    await expectLater(
      service.signIn(email: email, password: correctPassword),
      throwsAuthCode(LockoutAuthService.lockedCode),
    );

    expect(inner.signInCalls, callsBefore);
    expect(inner.currentUser, isNull);
  });

  test('nakon 15 minuta račun se otključava', () async {
    await failSignIn(5);

    now = now.add(const Duration(minutes: 15));
    inner.signInError = null;
    await service.signIn(email: email, password: correctPassword);

    expect(inner.currentUser?.email, email);
  });

  test('uspješna prijava resetira brojač', () async {
    await failSignIn(4);
    inner.signInError = null;
    await service.signIn(email: email, password: correctPassword);

    await failSignIn(4);
    inner.signInError = null;
    await service.signIn(email: email, password: correctPassword);

    expect(inner.currentUser?.email, email);
  });

  test('mrežne greške se ne broje', () async {
    inner.signInError = const AuthException('network-request-failed');
    for (var i = 0; i < 5; i++) {
      await expectLater(
        service.signIn(email: email, password: correctPassword),
        throwsAuthCode('network-request-failed'),
      );
    }

    inner.signInError = null;
    await service.signIn(email: email, password: correctPassword);

    expect(inner.currentUser?.email, email);
  });

  test('e-mail se uspoređuje bez obzira na velika slova i razmake', () async {
    await failSignIn(4);

    inner.signInError = const AuthException('invalid-credential');
    expect(
      service.signIn(email: '  ANA@opg.hr ', password: wrongPassword),
      throwsAuthCode(LockoutAuthService.lockedCode),
    );
  });
}
