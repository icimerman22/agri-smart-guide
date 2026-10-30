import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agri_smart_guide/app/app.dart';

void main() {
  testWidgets('Login, registration and demo home navigation works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AgriSmartGuideApp());

    expect(find.text('Prijava'), findsOneWidget);

    await tester.tap(find.text('Registracija'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Registracija'), findsOneWidget);

    await tester.tap(find.text('Povratak na prijavu'));
    await tester.pumpAndSettle();

    expect(find.text('Prijava'), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);

    await tester.tap(find.text('Nastavi na početnu (demo)'));
    await tester.pumpAndSettle();

    expect(find.text('Dobrodošli u Agri Smart Guide!'), findsOneWidget);

    await tester.tap(find.text('Povratak na prijavu'));
    await tester.pumpAndSettle();

    expect(find.text('Prijava'), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('System back returns from registration and demo home to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AgriSmartGuideApp());

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);

    for (final destination in ['Registracija', 'Nastavi na početnu (demo)']) {
      await tester.tap(find.text(destination));
      await tester.pumpAndSettle();

      expect(navigator.canPop(), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Prijava'), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    }
  });
}
