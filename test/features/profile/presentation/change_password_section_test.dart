import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/profile/presentation/profile_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/fake_profile_repository.dart';
import '../../../support/profile_test_helpers.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService(currentUser: testUser));

  Future<void> openProfile(WidgetTester tester) => pumpRoute(
    tester,
    AppRoutes.profile,
    auth: auth,
    repository: FakeProfileRepository(),
  );

  Future<void> submit(
    WidgetTester tester, {
    String current = '',
    String next = '',
    String confirm = '',
  }) async {
    await enterAuthText(tester, ProfileKeys.currentPassword, current);
    await enterAuthText(tester, ProfileKeys.newPassword, next);
    await enterAuthText(tester, ProfileKeys.confirmNewPassword, confirm);
    await tapAuthButton(tester, ProfileKeys.changePassword);
    await tester.pumpAndSettle();
  }

  group('Promjena lozinke', () {
    testWidgets('traži sva polja', (tester) async {
      await openProfile(tester);
      await submit(tester);

      expect(find.text('Molimo unesite trenutnu lozinku.'), findsOneWidget);
      expect(find.text('Molimo unesite lozinku.'), findsOneWidget);
      expect(find.text('Molimo potvrdite lozinku.'), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
    });

    testWidgets('provjerava duljinu i potvrdu nove lozinke', (tester) async {
      await openProfile(tester);
      await submit(tester, current: 'stara123', next: '123', confirm: '1234');

      expect(
        find.text('Lozinka mora imati najmanje 6 znakova.'),
        findsOneWidget,
      );
      expect(find.text('Lozinke se ne podudaraju.'), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
    });

    testWidgets('nova lozinka mora se razlikovati od trenutne', (tester) async {
      await openProfile(tester);
      await submit(
        tester,
        current: 'stara123',
        next: 'stara123',
        confirm: 'stara123',
      );

      expect(
        find.text('Nova lozinka mora se razlikovati od trenutne.'),
        findsOneWidget,
      );
      expect(auth.changePasswordCalls, 0);
    });

    testWidgets('mijenja lozinku i prazni polja', (tester) async {
      await openProfile(tester);
      await submit(
        tester,
        current: 'stara123',
        next: 'nova1234',
        confirm: 'nova1234',
      );

      expect(auth.changePasswordCalls, 1);
      expect(auth.lastCurrentPassword, 'stara123');
      expect(auth.lastNewPassword, 'nova1234');
      expect(find.text('Lozinka je uspješno promijenjena.'), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.descendant(
          of: find.byKey(ProfileKeys.currentPassword),
          matching: find.byType(TextFormField),
        ),
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('javlja pogrešnu trenutnu lozinku', (tester) async {
      auth.changePasswordError = const AuthException('invalid-credential');
      await openProfile(tester);
      await submit(
        tester,
        current: 'kriva123',
        next: 'nova1234',
        confirm: 'nova1234',
      );

      expect(find.text('Trenutna lozinka nije ispravna.'), findsOneWidget);
    });
  });
}
