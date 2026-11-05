import 'package:agri_smart_guide/app/firebase_setup.dart';
import 'package:agri_smart_guide/features/auth/presentation/auth_keys.dart';
import 'package:agri_smart_guide/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const testPassword = 'TestPassword123!';

void requireAuthEmulator() {
  if (!useAuthEmulator) {
    throw StateError(
      'Integration tests require --dart-define=USE_AUTH_EMULATOR=true',
    );
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

Future<void> startApp(WidgetTester tester) async {
  await app.main();
  await tester.pump();
}

Future<void> tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
}

Future<void> fillCredentials(
  WidgetTester tester,
  String email, {
  bool register = false,
  String password = testPassword,
}) async {
  final fields = {
    register ? AuthKeys.registerEmail : AuthKeys.loginEmail: email,
    register ? AuthKeys.registerPassword : AuthKeys.loginPassword: password,
    if (register) AuthKeys.registerConfirmPassword: password,
  };
  for (final field in fields.entries) {
    await tester.ensureVisible(find.byKey(field.key));
    await tester.enterText(find.byKey(field.key), field.value);
  }
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pump();
}
