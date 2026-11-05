import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/auth/presentation/register_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_test_helpers.dart';
import '../support/fake_auth_service.dart';

void expectNoPreviousRoute(WidgetTester tester) {
  expect(
    tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
    isFalse,
  );
}

void main() {
  testWidgets('Switching auth forms does not accumulate routes', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await pumpAuthApp(tester, auth, AppRoutes.login);

    for (var attempt = 0; attempt < 2; attempt++) {
      await tapAuthButton(tester, AuthKeys.goToRegister);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expectNoPreviousRoute(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tapAuthButton(tester, AuthKeys.goToLogin);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
      expectNoPreviousRoute(tester);
    }
    expect(auth.signInCalls, 0);
    expect(auth.registerCalls, 0);
  });

  for (final register in [false, true]) {
    testWidgets(
      '${register ? 'Registration' : 'Login'} opens home and Back cannot reopen an auth form',
      (tester) async {
        final auth = FakeAuthService();
        await pumpAuthApp(tester, auth, AppRoutes.login);
        if (register) {
          await tapAuthButton(tester, AuthKeys.goToRegister);
          await tester.pumpAndSettle();
        }
        await enterAuthText(
          tester,
          register ? AuthKeys.registerEmail : AuthKeys.loginEmail,
          'user@example.com',
        );
        await enterAuthText(
          tester,
          register ? AuthKeys.registerPassword : AuthKeys.loginPassword,
          'secret123',
        );
        if (register) {
          await enterAuthText(
            tester,
            AuthKeys.registerConfirmPassword,
            'secret123',
          );
        }
        await tapAuthButton(
          tester,
          register ? AuthKeys.registerSubmit : AuthKeys.loginSubmit,
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(auth.currentUser?.email, 'user@example.com');
        expect(find.textContaining('user@example.com'), findsOneWidget);
        expectNoPreviousRoute(tester);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  }

  for (final logoutKey in [AuthKeys.logout, AuthKeys.logoutIcon]) {
    testWidgets(
      'Logout using ${logoutKey.value} prevents Back from reopening home',
      (tester) async {
        final auth = FakeAuthService(
          currentUser: const AuthUser(uid: 'user-1', email: 'user@example.com'),
        );
        await pumpAuthApp(tester, auth, AppRoutes.home);
        await tapAuthButton(tester, logoutKey);
        await tester.pumpAndSettle();

        expect(auth.signOutCalls, 1);
        expect(auth.currentUser, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expectNoPreviousRoute(tester);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );
  }

  testWidgets('Failed logout keeps home and allows another attempt', (
    tester,
  ) async {
    const user = AuthUser(uid: 'user-1', email: 'user@example.com');
    final auth = FakeAuthService(currentUser: user)
      ..signOutError = const AuthException('network-request-failed');
    await pumpAuthApp(tester, auth, AppRoutes.home);
    await tapAuthButton(tester, AuthKeys.logout);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(auth.currentUser, same(user));

    auth.signOutError = null;
    await tapAuthButton(tester, AuthKeys.logout);
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 2);
    expect(auth.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
