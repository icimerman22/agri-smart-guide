import 'package:agri_smart_guide/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_service.dart';

Future<void> pumpAuthApp(
  WidgetTester tester,
  FakeAuthService auth,
  String initialRoute,
) async {
  await tester.pumpWidget(
    AgriSmartGuideApp(initialRoute: initialRoute, authService: auth),
  );
  await tester.pumpAndSettle();
}

Future<void> enterAuthText(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

Future<void> tapAuthButton(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
}
