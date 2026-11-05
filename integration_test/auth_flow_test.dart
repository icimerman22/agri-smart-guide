import 'package:agri_smart_guide/app/firebase_setup.dart';
import 'package:agri_smart_guide/features/auth/data/firebase_auth_service.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/auth_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseAuth auth;
  late FirebaseAuthService service;
  late String email;

  setUpAll(() async {
    requireAuthEmulator();
    auth = await initializeFirebase();
    service = FirebaseAuthService(auth: auth);
  });

  setUp(() async {
    await auth.signOut();
    email = 'integration-${DateTime.now().microsecondsSinceEpoch}@example.com';
  });

  tearDown(() async {
    try {
      if (auth.currentUser == null) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: testPassword,
        );
      }
      await auth.currentUser?.delete();
    } on FirebaseAuthException catch (error) {
      if (![
        'user-not-found',
        'invalid-credential',
        'wrong-password',
      ].contains(error.code)) {
        rethrow;
      }
    } finally {
      await auth.signOut();
    }
  });

  testWidgets('INT-01: registration, logout, login and logout use Firebase', (
    tester,
  ) async {
    await startApp(tester);
    await waitFor(tester, find.byType(LoginScreen));
    await tap(tester, AuthKeys.goToRegister);
    await tester.pumpAndSettle();
    await fillCredentials(tester, email, register: true);
    await tap(tester, AuthKeys.registerSubmit);
    await waitFor(tester, find.byType(HomeScreen));
    final uid = auth.currentUser!.uid;
    expect(auth.currentUser!.email, email);

    await tap(tester, AuthKeys.logout);
    await waitFor(tester, find.byType(LoginScreen));
    expect(auth.currentUser, isNull);
    await fillCredentials(tester, email);
    await tap(tester, AuthKeys.loginSubmit);
    await waitFor(tester, find.byType(HomeScreen));
    expect(auth.currentUser!.uid, uid);

    await tap(tester, AuthKeys.logoutIcon);
    await waitFor(tester, find.byType(LoginScreen));
    expect(auth.currentUser, isNull);
  });

  testWidgets('INT-02: duplicate registration displays Firebase error', (
    tester,
  ) async {
    await service.register(email: email, password: testPassword);
    await service.signOut();
    await startApp(tester);
    await tap(tester, AuthKeys.goToRegister);
    await tester.pumpAndSettle();
    await fillCredentials(tester, email, register: true);
    await tap(tester, AuthKeys.registerSubmit);
    await waitFor(
      tester,
      find.text('Račun s ovom e-mail adresom već postoji.'),
    );
    expect(auth.currentUser, isNull);
    expect(find.byType(HomeScreen), findsNothing);
  });

  for (final existingUser in [true, false]) {
    testWidgets(
      'INT-0${existingUser ? 3 : 4}: rejects ${existingUser ? 'wrong password' : 'unknown user'}',
      (tester) async {
        if (existingUser) {
          await service.register(email: email, password: testPassword);
          await service.signOut();
        }
        await startApp(tester);
        await fillCredentials(tester, email, password: 'WrongPassword123!');
        await tap(tester, AuthKeys.loginSubmit);
        await waitFor(
          tester,
          find.text('Neispravna e-mail adresa ili lozinka.'),
        );
        expect(auth.currentUser, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );
  }

  for (final invalidEmail in [true, false]) {
    testWidgets(
      'INT-0${invalidEmail ? 5 : 6}: Firebase rejects ${invalidEmail ? 'invalid email' : 'weak password'}',
      (tester) async {
        await expectLater(
          service.register(
            email: invalidEmail ? 'invalid-email' : email,
            password: invalidEmail ? testPassword : '123',
          ),
          throwsA(
            isA<AuthException>().having(
              (error) => error.code,
              'code',
              invalidEmail ? 'invalid-email' : 'weak-password',
            ),
          ),
        );
        expect(auth.currentUser, isNull);
      },
    );
  }
}
