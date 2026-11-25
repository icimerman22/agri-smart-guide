import 'dart:async';

import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';

Future<void> fillLogin(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'secret123',
}) async {
  await enterAuthText(tester, AuthKeys.loginEmail, email);
  await enterAuthText(tester, AuthKeys.loginPassword, password);
}

Future<void> startTotpSignIn(WidgetTester tester, FakeAuthService auth) async {
  await pumpAuthApp(tester, auth, AppRoutes.login);
  await fillLogin(tester);
  await tapAuthButton(tester, AuthKeys.loginSubmit);
  await tester.pumpAndSettle();
}

void main() {
  group('TOTP sign-in', () {
    testWidgets('waits for the second factor before opening home', (
      tester,
    ) async {
      final pending = Completer<void>();
      final auth = FakeAuthService()
        ..signInTotp = (code) async {
          expect(code, '012345');
          await pending.future;
        };

      await startTotpSignIn(tester, auth);

      expect(find.byType(HomeScreen), findsNothing);
      expect(auth.currentUser, isNull);
      await enterAuthText(tester, AuthKeys.loginTotpCode, '01234');
      await tapAuthButton(tester, AuthKeys.loginTotpSubmit);
      expect(find.text('Unesite šesteroznamenkasti kod.'), findsOneWidget);
      await enterAuthText(tester, AuthKeys.loginTotpCode, '012345');
      await tapAuthButton(tester, AuthKeys.loginTotpSubmit);
      expect(auth.currentUser, isNull);
      expect(find.byType(HomeScreen), findsNothing);

      pending.complete();
      await tester.pumpAndSettle();
      expect(auth.currentUser?.email, 'user@example.com');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('rejects an incorrect code and lets the user retry', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..signInTotp = (code) async {
          if (code != '123456') {
            throw const AuthException('invalid-verification-code');
          }
        };

      await startTotpSignIn(tester, auth);
      await enterAuthText(tester, AuthKeys.loginTotpCode, '000000');
      await tapAuthButton(tester, AuthKeys.loginTotpSubmit);
      await tester.pumpAndSettle();

      expect(
        find.text('Kod nije ispravan. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(auth.currentUser, isNull);
      expect(find.byType(HomeScreen), findsNothing);
      await enterAuthText(tester, AuthKeys.loginTotpCode, '123456');
      await tapAuthButton(tester, AuthKeys.loginTotpSubmit);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('returns to login after cancellation or expiration', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..signInTotp = (_) async {
          throw const AuthException('invalid-multi-factor-session');
        };

      await startTotpSignIn(tester, auth);
      await tapAuthButton(tester, AuthKeys.loginTotpCancel);
      await tester.pumpAndSettle();
      expect(find.byKey(AuthKeys.loginTotpCode), findsNothing);
      expect(auth.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await fillLogin(tester);
      await tapAuthButton(tester, AuthKeys.loginSubmit);
      await tester.pumpAndSettle();
      await enterAuthText(tester, AuthKeys.loginTotpCode, '123456');
      await tapAuthButton(tester, AuthKeys.loginTotpSubmit);
      await tester.pumpAndSettle();
      expect(find.byKey(AuthKeys.loginTotpCode), findsNothing);
      expect(
        find.text('Potvrda je istekla. Prijavite se ponovno.'),
        findsOneWidget,
      );
      expect(auth.currentUser, isNull);
      expect(find.byType(HomeScreen), findsNothing);
      expect(auth.signInCalls, 2);
    });
  });

  group('Login form validation', () {
    final scenarios = [
      (
        name: 'empty form',
        email: '',
        password: '',
        errors: ['Molimo unesite e-mail adresu.', 'Molimo unesite lozinku.'],
      ),
      (
        name: 'missing email',
        email: '',
        password: 'secret123',
        errors: ['Molimo unesite e-mail adresu.'],
      ),
      (
        name: 'missing password',
        email: 'user@example.com',
        password: '',
        errors: ['Molimo unesite lozinku.'],
      ),
      (
        name: 'whitespace input',
        email: '   ',
        password: '   ',
        errors: ['Molimo unesite e-mail adresu.', 'Molimo unesite lozinku.'],
      ),
      for (final email in [
        'user',
        'user@',
        '@example.com',
        'user@example',
        'user name@example.com',
      ])
        (
          name: 'invalid email: $email',
          email: email,
          password: 'secret123',
          errors: ['Unesite ispravnu e-mail adresu.'],
        ),
      (
        name: 'five-character password',
        email: 'user@example.com',
        password: '12345',
        errors: ['Lozinka mora imati najmanje 6 znakova.'],
      ),
    ];

    for (final scenario in scenarios) {
      testWidgets('rejects ${scenario.name} without calling auth', (
        tester,
      ) async {
        final auth = FakeAuthService();
        await pumpAuthApp(tester, auth, AppRoutes.login);
        await fillLogin(
          tester,
          email: scenario.email,
          password: scenario.password,
        );
        await tapAuthButton(tester, AuthKeys.loginSubmit);
        await tester.pumpAndSettle();

        for (final error in scenario.errors) {
          expect(find.text(error), findsOneWidget);
        }
        expect(auth.signInCalls, 0);
        expect(auth.currentUser, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      });
    }

    testWidgets(
      'allows a corrected form and preserves a six-character password',
      (tester) async {
        final auth = FakeAuthService();
        await pumpAuthApp(tester, auth, AppRoutes.login);
        await tapAuthButton(tester, AuthKeys.loginSubmit);
        await tester.pumpAndSettle();
        expect(find.text('Molimo unesite lozinku.'), findsOneWidget);

        await fillLogin(
          tester,
          email: ' user@example.com ',
          password: ' 1234 ',
        );
        await tapAuthButton(tester, AuthKeys.loginSubmit);
        await tester.pumpAndSettle();

        expect(auth.signInCalls, 1);
        expect(auth.lastEmail, 'user@example.com');
        expect(auth.lastPassword, ' 1234 ');
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });

  group('Login service responses', () {
    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found',
    ]) {
      testWidgets('shows credentials error for $code and allows retry', (
        tester,
      ) async {
        final auth = FakeAuthService()..signInError = AuthException(code);
        await pumpAuthApp(tester, auth, AppRoutes.login);
        await fillLogin(tester);
        await tapAuthButton(tester, AuthKeys.loginSubmit);
        await tester.pumpAndSettle();

        expect(
          find.text('Neispravna e-mail adresa ili lozinka.'),
          findsOneWidget,
        );
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(auth.currentUser, isNull);
        expect(
          tester
              .widget<ElevatedButton>(find.byKey(AuthKeys.loginSubmit))
              .onPressed,
          isNotNull,
        );

        auth.signInError = null;
        await tapAuthButton(tester, AuthKeys.loginSubmit);
        await tester.pumpAndSettle();
        expect(auth.signInCalls, 2);
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }

    testWidgets('prevents duplicate requests and navigation while signing in', (
      tester,
    ) async {
      final pending = Completer<void>();
      final auth = FakeAuthService()..signInGate = pending.future;
      await pumpAuthApp(tester, auth, AppRoutes.login);
      await fillLogin(tester);
      await tapAuthButton(tester, AuthKeys.loginSubmit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(AuthKeys.loginSubmit))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byKey(AuthKeys.goToRegister)).onPressed,
        isNull,
      );
      await tapAuthButton(tester, AuthKeys.loginSubmit);
      await tapAuthButton(tester, AuthKeys.goToRegister);
      expect(auth.signInCalls, 1);
      expect(find.byType(LoginScreen), findsOneWidget);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Google sign-in', () {
    testWidgets('login screen shows the Google sign-in button', (tester) async {
      await pumpAuthApp(tester, FakeAuthService(), AppRoutes.login);

      expect(find.byKey(AuthKeys.loginGoogle), findsOneWidget);
      expect(find.text('Prijava Googleom'), findsOneWidget);
    });

    testWidgets('tapping the button signs in and opens home', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthApp(tester, auth, AppRoutes.login);

      await tapAuthButton(tester, AuthKeys.loginGoogle);
      await tester.pumpAndSettle();

      expect(auth.googleSignInCalls, 1);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('cancelling keeps the user on login without an error', (
      tester,
    ) async {
      final auth = FakeAuthService()..googleSignInCancelled = true;
      await pumpAuthApp(tester, auth, AppRoutes.login);

      await tapAuthButton(tester, AuthKeys.loginGoogle);
      await tester.pumpAndSettle();

      expect(auth.googleSignInCalls, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.textContaining('pogreške'), findsNothing);
      expect(auth.currentUser, isNull);
    });

    testWidgets('shows an error when Google sign-in fails', (tester) async {
      final auth = FakeAuthService()
        ..googleSignInError = const AuthException(
          'network-error',
          message: 'x',
        );
      await pumpAuthApp(tester, auth, AppRoutes.login);

      await tapAuthButton(tester, AuthKeys.loginGoogle);
      await tester.pumpAndSettle();

      expect(find.textContaining('Došlo je do pogreške'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('prevents duplicate Google requests while signing in', (
      tester,
    ) async {
      final pending = Completer<void>();
      final auth = FakeAuthService()..googleSignInGate = pending.future;
      await pumpAuthApp(tester, auth, AppRoutes.login);

      await tapAuthButton(tester, AuthKeys.loginGoogle);
      await tapAuthButton(tester, AuthKeys.loginGoogle);
      expect(auth.googleSignInCalls, 1);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
    testWidgets('disables other buttons and shows a spinner while signing in', (
      tester,
    ) async {
      final pending = Completer<void>();
      final auth = FakeAuthService()..googleSignInGate = pending.future;
      await pumpAuthApp(tester, auth, AppRoutes.login);

      await tapAuthButton(tester, AuthKeys.loginGoogle);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(AuthKeys.loginSubmit))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byKey(AuthKeys.goToRegister)).onPressed,
        isNull,
      );

      pending.complete();
      await tester.pumpAndSettle();
    });
  });
}
