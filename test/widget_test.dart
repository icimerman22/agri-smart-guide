import 'package:agri_smart_guide/app/app.dart';
import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/auth/presentation/register_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_service.dart';

void main() {
  testWidgets('Login and registration share the injected service', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      AgriSmartGuideApp(initialRoute: AppRoutes.login, authService: auth),
    );
    expect(
      tester.widget<LoginScreen>(find.byType(LoginScreen)).authService,
      same(auth),
    );
    await tester.tap(find.byKey(AuthKeys.goToRegister));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(
      tester.widget<RegisterScreen>(find.byType(RegisterScreen)).authService,
      same(auth),
    );
    await tester.ensureVisible(find.byKey(AuthKeys.goToLogin));
    await tester.tap(find.byKey(AuthKeys.goToLogin));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('Sign in and sign out work without initializing Firebase', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      AgriSmartGuideApp(initialRoute: AppRoutes.login, authService: auth),
    );
    await tester.enterText(
      find.byKey(AuthKeys.loginEmail),
      ' user@example.com ',
    );
    await tester.enterText(find.byKey(AuthKeys.loginPassword), ' secret123 ');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pumpAndSettle();
    expect(auth.signInCalls, 1);
    expect(auth.lastEmail, 'user@example.com');
    expect(auth.lastPassword, ' secret123 ');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    await tester.tap(find.byKey(AuthKeys.logout));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(auth.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('Registration uses the injected service and opens home', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      AgriSmartGuideApp(initialRoute: AppRoutes.register, authService: auth),
    );
    await tester.enterText(
      find.byKey(AuthKeys.registerEmail),
      'new@example.com',
    );
    await tester.enterText(find.byKey(AuthKeys.registerPassword), 'secret123');
    await tester.enterText(
      find.byKey(AuthKeys.registerConfirmPassword),
      'secret123',
    );
    await tester.ensureVisible(find.byKey(AuthKeys.registerSubmit));
    await tester.tap(find.byKey(AuthKeys.registerSubmit));
    await tester.pumpAndSettle();
    expect(auth.registerCalls, 1);
    expect(auth.currentUser?.email, 'new@example.com');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });
}
