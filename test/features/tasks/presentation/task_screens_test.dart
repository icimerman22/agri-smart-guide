import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> pickDate(WidgetTester tester, String date) async {
  await tapAndSettle(tester, find.byTooltip('Switch to input'));
  await tester.enterText(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextFormField),
    ),
    date,
  );
  await tapAndSettle(tester, find.text('Potvrdi'));
}

void main() {
  testWidgets(
    'Home opens task management with validation, editing and deletion',
    (tester) async {
      final auth = FakeAuthService(
        currentUser: const AuthUser(uid: 'user-1', email: 'user@example.com'),
      );
      await pumpAuthApp(tester, auth, AppRoutes.home);

      await tapAndSettle(tester, find.text('Zadaci'));
      expect(find.text('Nemate dodanih zadataka.'), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip('Dodaj zadatak'));
      final title = find.widgetWithText(TextFormField, 'Naziv');
      final description = find.widgetWithText(
        TextFormField,
        'Opis (opcionalno)',
      );
      await tester.enterText(title, '   ');
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Unesite naziv zadatka.'), findsOneWidget);
      expect(find.text('Odaberite datum.'), findsOneWidget);

      await tester.enterText(title, '  Zalij vrt  ');
      await tester.enterText(description, 'Navečer');
      await tapAndSettle(tester, find.text('Odaberite datum'));
      await tapAndSettle(tester, find.text('Odustani'));
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Odaberite datum.'), findsOneWidget);

      await tapAndSettle(tester, find.text('Odaberite datum'));
      await pickDate(tester, '04/14/2030');
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Zalij vrt'), findsOneWidget);
      expect(find.text('14.04.2030\nNavečer'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Zadaci'));
      await tapAndSettle(tester, find.text('Zalij vrt'));
      expect(find.text('Uredi zadatak'), findsOneWidget);
      expect(tester.widget<TextFormField>(title).controller?.text, 'Zalij vrt');
      expect(
        tester.widget<TextFormField>(description).controller?.text,
        'Navečer',
      );
      expect(find.text('14.04.2030'), findsOneWidget);

      await tester.enterText(title, 'Zalij rajčice');
      await tester.enterText(description, '');
      await tapAndSettle(tester, find.text('14.04.2030'));
      await pickDate(tester, '04/15/2030');
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Zalij rajčice'), findsOneWidget);
      expect(find.text('Zalij vrt'), findsNothing);
      expect(find.text('15.04.2030'), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));
      await tapAndSettle(tester, find.text('Odustani'));
      expect(find.text('Zalij rajčice'), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));
      await tapAndSettle(tester, find.text('Obriši'));
      expect(find.text('Nemate dodanih zadataka.'), findsOneWidget);
    },
  );
}
