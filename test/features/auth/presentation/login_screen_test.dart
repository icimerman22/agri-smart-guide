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

void main() {
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

    testWidgets('allows a corrected form and preserves a six-character password', (
      tester,
    ) async {
      final auth = FakeAuthService();
      await pumpAuthApp(tester, auth, AppRoutes.login);
      await tapAuthButton(tester, AuthKeys.loginSubmit);
      await tester.pumpAndSettle();
      expect(find.text('Molimo unesite lozinku.'), findsOneWidget);

      await fillLogin(tester, email: ' user@example.com ', password: ' 1234 ');
      await tapAuthButton(tester, AuthKeys.loginSubmit);
      await tester.pumpAndSettle();

      expect(auth.signInCalls, 1);
      expect(auth.lastEmail, 'user@example.com');
      expect(auth.lastPassword, ' 1234 ');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
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
}
