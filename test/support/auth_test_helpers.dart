import 'package:agri_smart_guide/app/app.dart';
import 'package:agri_smart_guide/features/tasks/domain/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_service.dart';
import 'fake_profile_repository.dart';
import 'fake_task_repository.dart';

Future<void> pumpAuthApp(
  WidgetTester tester,
  FakeAuthService auth,
  String initialRoute, {
  TaskRepository? taskRepository,
}) async {
  await tester.pumpWidget(
    AgriSmartGuideApp(
      initialRoute: initialRoute,
      authService: auth,
      profileRepository: FakeProfileRepository(),
      taskRepository: taskRepository ?? FakeTaskRepository(),
    ),
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
