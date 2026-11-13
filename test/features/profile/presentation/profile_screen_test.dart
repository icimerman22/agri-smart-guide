import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/features/profile/presentation/profile_keys.dart';
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

  Future<void> openProfile(WidgetTester tester) =>
      pumpRoute(tester, AppRoutes.profile, auth: auth, repository: repository);

  group('Prikaz profila', () {
    testWidgets('prikazuje spremljene podatke i e-mail iz prijave', (
      tester,
    ) async {
      repository.profiles[testUser.uid] = savedProfile();
      await openProfile(tester);

      expect(find.text('Ana Horvat'), findsOneWidget);
      expect(find.text('ana@opg.hr'), findsNWidgets(2));
      expect(find.text('OPG Horvat'), findsOneWidget);
      final email = tester.widget<TextFormField>(
        find.descendant(
          of: find.byKey(ProfileKeys.email),
          matching: find.byType(TextFormField),
        ),
      );
      expect(email.enabled, isFalse);
    });

    testWidgets('novi korisnik vidi da profil nije dovršen', (tester) async {
      await openProfile(tester);

      expect(find.text('Profil nije dovršen'), findsOneWidget);
    });

    testWidgets('pri pogrešci učitavanja nudi ponovni pokušaj', (tester) async {
      repository.loadError = const ProfileException('unavailable');
      await openProfile(tester);

      expect(find.byKey(ProfileKeys.error), findsOneWidget);

      repository.loadError = null;
      repository.profiles[testUser.uid] = savedProfile();
      await tapAuthButton(tester, ProfileKeys.retry);
      await tester.pumpAndSettle();

      expect(find.text('Ana Horvat'), findsOneWidget);
      expect(repository.loadCalls, 2);
    });

    testWidgets('neprijavljeni korisnik ne vidi profil', (tester) async {
      auth.currentUser = null;
      await openProfile(tester);

      expect(find.text('Niste prijavljeni.'), findsOneWidget);
      expect(find.byKey(ProfileKeys.retry), findsNothing);
      expect(repository.loadCalls, 0);
    });
  });

  group('Uređivanje profila', () {
    testWidgets('prazna obavezna polja ne spremaju se', (tester) async {
      await openProfile(tester);
      await tapAuthButton(tester, ProfileKeys.save);
      await tester.pumpAndSettle();

      expect(find.text('Molimo unesite ime.'), findsOneWidget);
      expect(find.text('Molimo unesite prezime.'), findsOneWidget);
      expect(repository.saveCalls, 0);
    });

    testWidgets('sprema ispravne podatke i prikazuje poruku o uspjehu', (
      tester,
    ) async {
      await openProfile(tester);
      await enterAuthText(tester, ProfileKeys.firstName, '  Ana  ');
      await enterAuthText(tester, ProfileKeys.lastName, 'Horvat');
      await enterAuthText(tester, ProfileKeys.farmName, 'OPG Horvat');
      await tapAuthButton(tester, ProfileKeys.save);
      await tester.pumpAndSettle();

      final saved = repository.profiles[testUser.uid]!;
      expect(saved.firstName, 'Ana');
      expect(saved.lastName, 'Horvat');
      expect(saved.farmName, 'OPG Horvat');
      expect(find.text('Promjene su uspješno spremljene.'), findsOneWidget);
      expect(find.text('Ana Horvat'), findsOneWidget);
    });

    testWidgets('neuspjelo spremanje prikazuje poruku', (tester) async {
      repository.saveError = const ProfileException('unavailable');
      await openProfile(tester);
      await enterAuthText(tester, ProfileKeys.firstName, 'Ana');
      await enterAuthText(tester, ProfileKeys.lastName, 'Horvat');
      await tapAuthButton(tester, ProfileKeys.save);
      await tester.pumpAndSettle();

      expect(
        find.text('Promjene nije moguće spremiti. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(repository.profiles, isEmpty);
    });
  });

  group('Navigacija', () {
    testWidgets('ikona na početnom zaslonu otvara profil', (tester) async {
      await pumpAuthApp(tester, auth, AppRoutes.home);
      await tester.tap(find.byKey(ProfileKeys.openProfile));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileKeys.header), findsOneWidget);
    });

    testWidgets('ikona postavki otvara zaslon postavki', (tester) async {
      await openProfile(tester);
      await tester.tap(find.byKey(ProfileKeys.openSettings));
      await tester.pumpAndSettle();

      expect(find.text('Postavke'), findsOneWidget);
      expect(find.text('Obavijesti'), findsOneWidget);
    });
  });
}
