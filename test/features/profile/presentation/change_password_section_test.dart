import 'dart:async';

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

  Future<void> startPasswordChangeWithTotp(
    WidgetTester tester, {
    TotpVerifier? verify,
  }) async {
    auth.changePasswordTotp =
        verify ??
        (code) async {
          if (code != '012345') {
            throw const AuthException('invalid-verification-code');
          }
        };
    await openProfile(tester);
    await submit(
      tester,
      current: 'stara123',
      next: 'nova1234',
      confirm: 'nova1234',
    );
  }

  Future<void> confirmTotp(WidgetTester tester, String code) async {
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)),
      code,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Potvrdi'));
    await tester.pumpAndSettle();
  }

  group('Promjena lozinke', () {
    testWidgets('mijenja lozinku tek nakon ispravnog TOTP koda', (
      tester,
    ) async {
      await startPasswordChangeWithTotp(tester);

      expect(find.text('Potvrdite promjenu lozinke'), findsOneWidget);
      expect(auth.passwordUpdates, 0);
      await confirmTotp(tester, '000000');

      expect(
        find.text('Kod nije ispravan. Pokušajte ponovno.'),
        findsOneWidget,
      );
      expect(find.text('Lozinka je uspješno promijenjena.'), findsNothing);
      expect(auth.passwordUpdates, 0);

      await confirmTotp(tester, '012345');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Lozinka je uspješno promijenjena.'), findsOneWidget);
      expect(auth.passwordUpdates, 1);
    });

    testWidgets('odustajanje od TOTP potvrde ne mijenja lozinku', (
      tester,
    ) async {
      await startPasswordChangeWithTotp(tester);

      expect(find.text('Potvrdite promjenu lozinke'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Odustani'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Lozinka je uspješno promijenjena.'), findsNothing);
      expect(auth.passwordUpdates, 0);
      expect(
        tester
            .widget<OutlinedButton>(
              find.descendant(
                of: find.byKey(ProfileKeys.changePassword),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('nakon isteka TOTP potvrde mora pokrenuti novu promjenu', (
      tester,
    ) async {
      await startPasswordChangeWithTotp(
        tester,
        verify: (_) async {
          throw const AuthException('invalid-multi-factor-session');
        },
      );
      await confirmTotp(tester, '012345');

      expect(
        find.text('Potvrda je istekla. Pokrenite promjenu ponovno.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Potvrdi'))
            .onPressed,
        isNull,
      );
      expect(auth.passwordUpdates, 0);

      await tester.tap(find.widgetWithText(TextButton, 'Odustani'));
      await tester.pumpAndSettle();
      auth.changePasswordTotp = (_) async {};
      await submit(
        tester,
        current: 'stara123',
        next: 'nova1234',
        confirm: 'nova1234',
      );
      await confirmTotp(tester, '012345');

      expect(auth.changePasswordCalls, 2);
      expect(auth.passwordUpdates, 1);
    });

    testWidgets('ne dopušta dvostruku potvrdu ili izlazak dok provjera traje', (
      tester,
    ) async {
      final pending = Completer<void>();
      var verificationCalls = 0;
      await startPasswordChangeWithTotp(
        tester,
        verify: (_) {
          verificationCalls++;
          return pending.future;
        },
      );
      await confirmTotp(tester, '012345');

      final confirm = find.widgetWithText(TextButton, 'Provjera…');
      final cancel = find.widgetWithText(TextButton, 'Odustani');
      expect(tester.widget<TextButton>(confirm).onPressed, isNull);
      expect(tester.widget<TextButton>(cancel).onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(verificationCalls, 1);
      expect(auth.passwordUpdates, 0);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.passwordUpdates, 1);
    });

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
      expect(auth.passwordUpdates, 1);
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
