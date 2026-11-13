import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/profile/domain/profile_repository.dart';
import 'package:agri_smart_guide/shared/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_service.dart';
import 'fake_profile_repository.dart';

const testUser = AuthUser(uid: 'u1', email: 'ana@opg.hr');

UserProfile savedProfile({
  String firstName = 'Ana',
  String lastName = 'Horvat',
  String farmName = 'OPG Horvat',
}) => defaultUserProfile(
  testUser.uid,
  Timestamp(0, 0),
).copyWith(firstName: firstName, lastName: lastName, farmName: farmName);

/// Opens [route] with all app routes, on a tall screen so whole forms fit.
Future<void> pumpRoute(
  WidgetTester tester,
  String route, {
  required FakeAuthService auth,
  required FakeProfileRepository repository,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      initialRoute: route,
      routes: AppRoutes.routes(auth, repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> selectDropdownItem(
  WidgetTester tester,
  Key dropdownKey,
  String itemText,
) async {
  await tester.tap(find.byKey(dropdownKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(itemText).last);
  await tester.pumpAndSettle();
}
