import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/features/profile/presentation/profile_keys.dart';
import 'package:agri_smart_guide/features/settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/fake_profile_repository.dart';
import '../../../support/profile_test_helpers.dart';

void main() {
  late FakeAuthService auth;
  late FakeProfileRepository repository;

  setUp(() {
    auth = FakeAuthService(currentUser: testUser);
    repository = FakeProfileRepository();
  });

  Future<void> openSettings(WidgetTester tester) =>
      pumpRoute(tester, AppRoutes.settings, auth: auth, repository: repository);

  bool switchValue(WidgetTester tester, String type) => tester
      .widget<SwitchListTile>(find.byKey(SettingsKeys.notification(type)))
      .value;

  Future<void> openTotpSetup(WidgetTester tester) async {
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final enableTotp = find.text('Uključi 2FA');
    expect(enableTotp, findsOneWidget);
    await tester.tap(enableTotp);
    await tester.pumpAndSettle();
  }

  Future<void> submitTotpField(
    WidgetTester tester,
    String value,
    String button,
  ) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      value,
    );
    await tester.tap(find.widgetWithText(TextButton, button));
    await tester.pumpAndSettle();
  }

  group('Postavke', () {
    testWidgets('prije uključivanja 2FA traži potvrdu e-adrese', (
      tester,
    ) async {
      await openTotpSetup(tester);

      expect(
        find.text('Potvrdite e-adresu prije uključivanja 2FA.'),
        findsOneWidget,
      );
      expect(find.text('Pošalji poruku za potvrdu'), findsOneWidget);
      expect(find.text('Ključ za postavljanje'), findsNothing);
      await tester.tap(find.text('Pošalji poruku za potvrdu'));
      await tester.pumpAndSettle();
      expect(auth.totpVerificationEmails, 1);

      auth.totpEmailVerified = true;
      await tester.tap(find.text('Provjeri potvrdu'));
      await tester.pumpAndSettle();
      expect(find.text('Trenutna lozinka'), findsOneWidget);
      expect(find.text('Ključ za postavljanje'), findsNothing);
    });

    testWidgets('2FA se uključuje tek nakon potvrde točnog koda', (
      tester,
    ) async {
      auth.totpEmailVerified = true;
      await openTotpSetup(tester);
      expect(find.text('Ključ za postavljanje'), findsNothing);

      await submitTotpField(tester, 'stara123', 'Nastavi');
      expect(auth.lastTotpPassword, 'stara123');
      expect(find.text('Ključ za postavljanje'), findsOneWidget);
      expect(auth.totpEnabled, isFalse);

      await submitTotpField(tester, '000000', 'Potvrdi');
      expect(
        find.text('Kod nije ispravan. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(auth.totpEnabled, isFalse);

      await submitTotpField(tester, '012345', 'Potvrdi');
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.totpEnabled, isTrue);
      expect(find.text('2FA je uključen'), findsOneWidget);
    });

    testWidgets('odustajanje napušta postavljanje bez aktivacije', (
      tester,
    ) async {
      auth.totpEmailVerified = true;
      await openTotpSetup(tester);
      await submitTotpField(tester, 'stara123', 'Nastavi');
      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();
      expect(auth.totpEnabled, isFalse);
      expect(find.text('Ključ za postavljanje'), findsNothing);
      expect(find.text('Uključi 2FA'), findsOneWidget);
    });

    testWidgets('novi korisnik vidi zadane postavke', (tester) async {
      await openSettings(tester);

      expect(switchValue(tester, 'taskDeadlines'), isTrue);
      expect(switchValue(tester, 'weatherAlerts'), isTrue);
      expect(switchValue(tester, 'recommendations'), isTrue);
      expect(switchValue(tester, 'dayBeforeReminder'), isFalse);
      expect(find.text('Metričke (°C, mm, ha)'), findsOneWidget);
      expect(find.text('Odaberite lokaciju'), findsOneWidget);
    });

    testWidgets('promjena obavijesti odmah se sprema', (tester) async {
      await openSettings(tester);
      await tester.tap(
        find.byKey(SettingsKeys.notification('dayBeforeReminder')),
      );
      await tester.pumpAndSettle();

      final settings = repository.profiles[testUser.uid]!.notificationSettings;
      expect(settings['dayBeforeReminder'], isTrue);
      expect(settings['taskDeadlines'], isTrue);
      expect(switchValue(tester, 'dayBeforeReminder'), isTrue);
    });

    testWidgets('lokacija i mjerne jedinice se spremaju', (tester) async {
      await openSettings(tester);
      await selectDropdownItem(tester, ProfileKeys.location, 'Varaždin');
      await selectDropdownItem(
        tester,
        SettingsKeys.unitSystem,
        'Imperijalne (°F, in, ac)',
      );

      final saved = repository.profiles[testUser.uid]!;
      expect(saved.primaryLocation['name'], 'Varaždin');
      expect(saved.primaryLocation['latitude'], 46.3057);
      expect(saved.unitSystem, 'imperial');
    });

    testWidgets(
      'spremljene vrijednosti prikazuju se nakon ponovnog otvaranja',
      (tester) async {
        repository.profiles[testUser.uid] = savedProfile().copyWith(
          unitSystem: 'imperial',
          primaryLocation: {
            'name': 'Osijek',
            'latitude': 45.5550,
            'longitude': 18.6955,
          },
          notificationSettings: {'weatherAlerts': false},
        );
        await openSettings(tester);

        expect(find.text('Imperijalne (°F, in, ac)'), findsOneWidget);
        expect(find.text('Osijek'), findsOneWidget);
        expect(switchValue(tester, 'weatherAlerts'), isFalse);
        expect(switchValue(tester, 'taskDeadlines'), isTrue);
      },
    );

    testWidgets('neuspjelo spremanje vraća prethodnu vrijednost', (
      tester,
    ) async {
      repository.saveError = const ProfileException('unavailable');
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsKeys.notification('taskDeadlines')));
      await tester.pumpAndSettle();

      expect(
        find.text('Promjenu nije moguće spremiti. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(switchValue(tester, 'taskDeadlines'), isTrue);
    });

    testWidgets('pogreška učitavanja nudi ponovni pokušaj', (tester) async {
      repository.loadError = const ProfileException('unavailable');
      await openSettings(tester);

      expect(find.byKey(SettingsKeys.error), findsOneWidget);
      expect(find.byKey(SettingsKeys.retry), findsOneWidget);
    });
  });

  group('Odjava', () {
    testWidgets('odjavljuje korisnika i ne dopušta povratak', (tester) async {
      await pumpAuthApp(tester, auth, AppRoutes.home);
      await tester.tap(find.byKey(ProfileKeys.openProfile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProfileKeys.openSettings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(SettingsKeys.logout), 150);
      await tapAuthButton(tester, SettingsKeys.logout);
      await tester.pumpAndSettle();

      expect(auth.signOutCalls, 1);
      expect(auth.currentUser, isNull);
      expect(find.byKey(AuthKeys.loginSubmit), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });

    testWidgets('neuspjela odjava ostaje na postavkama', (tester) async {
      auth.signOutError = const AuthException('network-request-failed');
      await openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(SettingsKeys.logout), 150);
      await tapAuthButton(tester, SettingsKeys.logout);
      await tester.pumpAndSettle();

      expect(
        find.text('Odjava nije uspjela. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(find.byKey(SettingsKeys.logout), findsOneWidget);
    });
  });
}
