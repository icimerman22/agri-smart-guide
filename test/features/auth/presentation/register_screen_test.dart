import 'dart:async';

import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/register_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';

Future<void> fillRegistration(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'secret123',
  String confirmation = 'secret123',
}) async {
  await enterAuthText(tester, AuthKeys.registerEmail, email);
  await enterAuthText(tester, AuthKeys.registerPassword, password);
  await enterAuthText(tester, AuthKeys.registerConfirmPassword, confirmation);
}

void main() {
  group('Registration form validation', () {
    final scenarios = [
      (
        name: 'empty form',
        email: '',
        password: '',
        confirmation: '',
        errors: [
          'Molimo unesite e-mail adresu.',
          'Molimo unesite lozinku.',
          'Molimo potvrdite lozinku.',
        ],
      ),
      (
        name: 'missing email',
        email: '',
        password: 'secret123',
        confirmation: 'secret123',
        errors: ['Molimo unesite e-mail adresu.'],
      ),
      (
        name: 'missing password',
        email: 'user@example.com',
        password: '',
        confirmation: 'secret123',
        errors: ['Molimo unesite lozinku.', 'Lozinke se ne podudaraju.'],
      ),
      (
        name: 'missing confirmation',
        email: 'user@example.com',
        password: 'secret123',
        confirmation: '',
        errors: ['Molimo potvrdite lozinku.'],
      ),
      (
        name: 'whitespace email',
        email: '   ',
        password: 'secret123',
        confirmation: 'secret123',
        errors: ['Molimo unesite e-mail adresu.'],
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
          confirmation: 'secret123',
          errors: ['Unesite ispravnu e-mail adresu.'],
        ),
      (
        name: 'five-character password',
        email: 'user@example.com',
        password: '12345',
        confirmation: '12345',
        errors: ['Lozinka mora imati najmanje 6 znakova.'],
      ),
      (
        name: 'mismatched passwords',
        email: 'user@example.com',
        password: 'secret123',
        confirmation: 'Secret123',
        errors: ['Lozinke se ne podudaraju.'],
      ),
    ];

    for (final scenario in scenarios) {
      testWidgets('rejects ${scenario.name} without calling auth', (
        tester,
      ) async {
        final auth = FakeAuthService();
        await pumpAuthApp(tester, auth, AppRoutes.register);
        await fillRegistration(
          tester,
          email: scenario.email,
          password: scenario.password,
          confirmation: scenario.confirmation,
        );
        await tapAuthButton(tester, AuthKeys.registerSubmit);
        await tester.pumpAndSettle();

        for (final error in scenario.errors) {
          expect(find.text(error), findsOneWidget);
        }
        expect(auth.registerCalls, 0);
        expect(auth.currentUser, isNull);
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      });
    }

    testWidgets('clears validation errors after correction and submits', (
      tester,
    ) async {
      final auth = FakeAuthService();
      await pumpAuthApp(tester, auth, AppRoutes.register);
      await tapAuthButton(tester, AuthKeys.registerSubmit);
      await tester.pumpAndSettle();
      expect(find.text('Molimo potvrdite lozinku.'), findsOneWidget);

      await fillRegistration(
        tester,
        email: ' user@example.com ',
        password: '123456',
        confirmation: '123456',
      );
      await tester.pumpAndSettle();
      expect(find.text('Molimo unesite e-mail adresu.'), findsNothing);
      expect(find.text('Molimo unesite lozinku.'), findsNothing);
      expect(find.text('Molimo potvrdite lozinku.'), findsNothing);
      expect(auth.registerCalls, 0);

      await tapAuthButton(tester, AuthKeys.registerSubmit);
      await tester.pumpAndSettle();
      expect(auth.registerCalls, 1);
      expect(auth.lastEmail, 'user@example.com');
      expect(auth.lastPassword, '123456');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Registration service responses', () {
    final errors = {
      'email-already-in-use': 'Račun s ovom e-mail adresom već postoji.',
      'weak-password': 'Lozinka je preslaba. Odaberite jaču lozinku.',
      'network-request-failed':
          'Nema internetske veze. Provjerite vezu i pokušajte ponovno.',
      'unknown': 'Registracija nije uspjela. Pokušajte ponovno.',
    };
    for (final error in errors.entries) {
      testWidgets('shows ${error.key} and allows retry', (tester) async {
        final auth = FakeAuthService()
          ..registerError = AuthException(error.key);
        await pumpAuthApp(tester, auth, AppRoutes.register);
        await fillRegistration(tester);
        await tapAuthButton(tester, AuthKeys.registerSubmit);
        await tester.pumpAndSettle();
        expect(find.text(error.value), findsOneWidget);
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(auth.currentUser, isNull);

        auth.registerError = null;
        await tapAuthButton(tester, AuthKeys.registerSubmit);
        await tester.pumpAndSettle();
        expect(auth.registerCalls, 2);
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }

    testWidgets(
      'prevents duplicate requests and navigation during registration',
      (tester) async {
        final pending = Completer<void>();
        final auth = FakeAuthService()..registerGate = pending.future;
        await pumpAuthApp(tester, auth, AppRoutes.register);
        await fillRegistration(tester);
        await tapAuthButton(tester, AuthKeys.registerSubmit);
        expect(find.text('Registracija u tijeku...'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.descendant(
                  of: find.byKey(AuthKeys.registerSubmit),
                  matching: find.byType(FilledButton),
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester.widget<TextButton>(find.byKey(AuthKeys.goToLogin)).onPressed,
          isNull,
        );
        await tapAuthButton(tester, AuthKeys.registerSubmit);
        await tapAuthButton(tester, AuthKeys.goToLogin);
        expect(auth.registerCalls, 1);
        expect(find.byType(RegisterScreen), findsOneWidget);

        pending.complete();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
