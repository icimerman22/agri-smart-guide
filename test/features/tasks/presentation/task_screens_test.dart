import 'package:agri_smart_guide/app/routes.dart';
import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/auth/presentation/login_screen.dart';
import 'package:agri_smart_guide/features/home/presentation/home_screen.dart';
import 'package:agri_smart_guide/shared/models/farm_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_helpers.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/fake_task_repository.dart';

const alice = AuthUser(uid: 'alice', email: 'alice@example.com');
const bob = AuthUser(uid: 'bob', email: 'bob@example.com');

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
    'Title and date are required independently, description is optional',
    (tester) async {
      final repository = FakeTaskRepository();
      await pumpAuthApp(
        tester,
        FakeAuthService(currentUser: alice),
        AppRoutes.home,
        taskRepository: repository,
      );
      await tapAndSettle(tester, find.text('Zadaci'));
      await tapAndSettle(tester, find.byTooltip('Dodaj zadatak'));
      final title = find.widgetWithText(TextFormField, 'Naziv');
      final save = find.text('Spremi');

      await tester.enterText(title, 'Zalij vrt');
      await tapAndSettle(tester, save);
      expect(find.text('Odaberite datum.'), findsOneWidget);
      expect(find.text('Unesite naziv zadatka.'), findsNothing);
      expect(repository.tasksFor(alice.uid), isEmpty);

      await tapAndSettle(tester, find.text('Odaberite datum'));
      await pickDate(tester, '04/14/2030');
      await tester.enterText(title, '   ');
      await tapAndSettle(tester, save);
      expect(find.text('Unesite naziv zadatka.'), findsOneWidget);
      expect(find.text('Odaberite datum.'), findsNothing);
      expect(repository.tasksFor(alice.uid), isEmpty);

      await tester.enterText(title, 'Zalij vrt');
      await tapAndSettle(tester, save);
      final task = repository.tasksFor(alice.uid).single;
      expect(task.description, isEmpty);
      expect(find.text('Zalij vrt'), findsOneWidget);
      expect(find.text('14.04.2030 • Neizvršen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(repository.isWatching(alice.uid), isFalse);
      await pumpAuthApp(
        tester,
        FakeAuthService(currentUser: alice),
        AppRoutes.home,
        taskRepository: repository,
      );
      await tapAndSettle(tester, find.text('Zadaci'));
      expect(find.text('Zalij vrt'), findsOneWidget);

      await repository.updateTask(
        FarmTask.fromMap(task.id, {...task.toMap(), 'title': 'Zalij rajčice'}),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zalij vrt'), findsNothing);
      expect(find.text('Zalij rajčice'), findsOneWidget);
    },
  );

  testWidgets(
    'Home opens task management with validation, editing and deletion',
    (tester) async {
      final auth = FakeAuthService(currentUser: alice);
      final repository = FakeTaskRepository();
      await pumpAuthApp(
        tester,
        auth,
        AppRoutes.home,
        taskRepository: repository,
      );

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
      repository.failNextWrite = true;
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Spremanje zadatka nije uspjelo.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(description).controller?.text,
        'Navečer',
      );
      expect(repository.tasksFor(alice.uid), isEmpty);
      await tapAndSettle(tester, find.text('Spremi'));
      expect(find.text('Zalij vrt'), findsOneWidget);
      expect(find.text('14.04.2030 • Neizvršen\nNavečer'), findsOneWidget);

      await tapAndSettle(tester, find.byType(Checkbox));
      expect(find.text('14.04.2030 • Izvršen\nNavečer'), findsOneWidget);
      expect(repository.tasksFor(alice.uid).single.isCompleted, isTrue);

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
      expect(find.text('15.04.2030 • Izvršen'), findsOneWidget);

      repository.failNextWrite = true;
      await tapAndSettle(tester, find.byType(Checkbox));
      expect(
        find.text('Promjena statusa zadatka nije uspjela.'),
        findsOneWidget,
      );
      expect(find.text('15.04.2030 • Izvršen'), findsOneWidget);
      await tapAndSettle(tester, find.byType(Checkbox));
      expect(find.text('15.04.2030 • Neizvršen'), findsOneWidget);
      expect(repository.tasksFor(alice.uid).single.isCompleted, isFalse);

      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));
      await tapAndSettle(tester, find.text('Odustani'));
      expect(find.text('Zalij rajčice'), findsOneWidget);
      repository.failNextWrite = true;
      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));
      await tapAndSettle(tester, find.text('Obriši'));
      expect(find.text('Brisanje zadatka nije uspjelo.'), findsOneWidget);
      expect(find.text('Zalij rajčice'), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));
      await tapAndSettle(tester, find.text('Obriši'));
      expect(find.text('Nemate dodanih zadataka.'), findsOneWidget);
    },
  );

  testWidgets(
    'Changing accounts or signing out discards task routes and listeners',
    (tester) async {
      final auth = FakeAuthService(currentUser: alice);
      final repository = FakeTaskRepository();
      final now = Timestamp.now();
      for (final user in [alice, bob]) {
        await repository.createTask(
          FarmTask(
            id: '',
            ownerId: user.uid,
            title: 'Zadatak ${user.uid}',
            description: '',
            type: 'general',
            dueAt: Timestamp.fromDate(DateTime.utc(2030, 4, 14)),
            priority: 'normal',
            status: FarmTask.pendingStatus,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      await pumpAuthApp(
        tester,
        auth,
        AppRoutes.home,
        taskRepository: repository,
      );
      await tapAndSettle(tester, find.text('Zadaci'));
      expect(repository.isWatching(alice.uid), isTrue);
      await tapAndSettle(tester, find.text('Zadatak alice'));
      expect(find.text('Uredi zadatak'), findsOneWidget);

      auth.currentUser = bob;
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Uredi zadatak', skipOffstage: false), findsNothing);
      expect(repository.isWatching(alice.uid), isFalse);
      await tapAndSettle(tester, find.text('Zadaci'));
      expect(find.text('Zadatak bob'), findsOneWidget);
      expect(find.text('Zadatak alice'), findsNothing);
      expect(repository.isWatching(bob.uid), isTrue);
      await tapAndSettle(tester, find.byTooltip('Obriši zadatak'));

      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
      expect(find.text('Zadatak bob', skipOffstage: false), findsNothing);
      expect(repository.isWatching(bob.uid), isFalse);
    },
  );

  testWidgets('Opening a protected route while signed out shows login', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    await pumpAuthApp(
      tester,
      FakeAuthService(),
      AppRoutes.home,
      taskRepository: repository,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Zadaci'), findsNothing);
  });
}
