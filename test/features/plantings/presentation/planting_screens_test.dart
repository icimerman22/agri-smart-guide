import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/crops/data/local_crop_data_source.dart';
import 'package:agri_smart_guide/features/crops/domain/models/crop_model.dart';
import 'package:agri_smart_guide/features/plantings/data/firestore_planting_repository.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_detail_screen.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_form_screen.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_keys.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_list_screen.dart';
import 'package:agri_smart_guide/features/plots/data/plot_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_service.dart';
import '../../../support/planting_test_helpers.dart';

class _FakeCropDataSource extends LocalCropDataSource {
  @override
  Future<List<CropModel>> loadCrops() async => const [
    CropModel(
      id: 'tomato',
      name: 'Rajčica',
      description: 'Povrtna kultura',
      plantingPeriod: 'Proljeće',
      growingConditions: 'Sunčan položaj',
      growingDurationDays: 90,
      waterNeeds: 'Redovito zalijevanje',
    ),
    CropModel(
      id: 'lettuce',
      name: 'Salata',
      description: 'Lisnata kultura',
      plantingPeriod: 'Proljeće',
      growingConditions: 'Umjerene temperature',
      growingDurationDays: 50,
      waterNeeds: 'Redovito zalijevanje',
    ),
  ];
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeAuthService auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = FakeAuthService(currentUser: const AuthUser(uid: 'alice'));
  });

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlantingListScreen(
          authService: auth,
          plotRepository: PlotRepository(firestore: firestore),
          plantingRepository: FirestorePlantingRepository(firestore: firestore),
          cropDataSource: _FakeCropDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDetail(WidgetTester tester, String plantingId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlantingDetailScreen(
          plantingId: plantingId,
          authService: auth,
          plotRepository: PlotRepository(firestore: firestore),
          plantingRepository: FirestorePlantingRepository(firestore: firestore),
          cropDataSource: _FakeCropDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> plantingData(String id) async =>
      (await firestore.doc('plantings/$id').get()).data()!;

  group('PlantingListScreen', () {
    testWidgets('prikazuje kulturu, parcelu i datum sadnje', (tester) async {
      await seedParcel(firestore, 'p1', name: 'Moja njiva');
      await seedPlanting(firestore, 'a', parcelId: 'p1', cropId: 'tomato');

      await pumpList(tester);

      expect(find.text('Rajčica'), findsOneWidget);
      expect(find.textContaining('Moja njiva'), findsOneWidget);
      expect(find.textContaining('01.01.1970'), findsOneWidget);
      expect(find.textContaining('Posađeno'), findsOneWidget);
      expect(find.textContaining('Aktivna'), findsOneWidget);
    });

    testWidgets('prikazuje samo sadnje prijavljenog korisnika', (tester) async {
      await seedParcel(firestore, 'p1', name: 'Moja njiva');
      await seedParcel(firestore, 'p2', ownerId: 'bob', name: 'Tuđi vrt');
      await seedPlanting(firestore, 'a', parcelId: 'p1', cropId: 'tomato');
      await seedPlanting(
        firestore,
        'b',
        ownerId: 'bob',
        parcelId: 'p2',
        cropId: 'lettuce',
      );

      await pumpList(tester);

      expect(find.byKey(PlantingKeys.listItem('a')), findsOneWidget);
      expect(find.byKey(PlantingKeys.listItem('b')), findsNothing);
      expect(find.text('Salata'), findsNothing);
    });

    testWidgets('prikazuje poruku kad nema sadnji', (tester) async {
      await pumpList(tester);

      expect(find.byKey(PlantingKeys.listEmpty), findsOneWidget);
    });

    testWidgets('gumb s plusom otvara formu za evidentiranje sadnje', (
      tester,
    ) async {
      await pumpList(tester);

      await tester.tap(find.byKey(PlantingKeys.openPlantingForm));
      await tester.pumpAndSettle();

      expect(find.byType(PlantingFormScreen), findsOneWidget);
    });

    testWidgets('dodir na stavku otvara detalje', (tester) async {
      await seedParcel(firestore, 'p1', name: 'Moja njiva');
      await seedPlanting(firestore, 'a', parcelId: 'p1');

      await pumpList(tester);
      await tester.tap(find.byKey(PlantingKeys.listItem('a')));
      await tester.pumpAndSettle();

      expect(find.byType(PlantingDetailScreen), findsOneWidget);
      expect(find.text('Detalji sadnje'), findsOneWidget);
    });
  });

  group('PlantingDetailScreen', () {
    testWidgets('promjena faze sprema se u Firestore', (tester) async {
      await seedParcel(firestore, 'p1', activePlantingId: 'a');
      await seedPlanting(firestore, 'a', parcelId: 'p1');
      await pumpDetail(tester, 'a');

      await tester.tap(find.byKey(PlantingKeys.stageField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cvatnja').last);
      await tester.pumpAndSettle();

      expect((await plantingData('a'))['stage'], 'flowering');
      expect(find.text('Razvojna faza je ažurirana.'), findsOneWidget);
    });

    testWidgets('isključivanje prekidača završava uzgoj i oslobađa parcelu', (
      tester,
    ) async {
      await seedParcel(firestore, 'p1', activePlantingId: 'a');
      await seedPlanting(firestore, 'a', parcelId: 'p1');
      await pumpDetail(tester, 'a');

      await tester.tap(find.byKey(PlantingKeys.statusSwitch));
      await tester.pumpAndSettle();

      expect((await plantingData('a'))['status'], 'completed');
      final parcel = (await firestore.doc('parcels/p1').get()).data()!;
      expect(parcel['activePlantingId'], isNull);
      expect(find.text('Završena'), findsOneWidget);
      expect(find.text('Status uzgoja je ažuriran.'), findsOneWidget);
    });

    testWidgets('ponovna aktivacija na zauzetoj parceli prikazuje grešku', (
      tester,
    ) async {
      await seedParcel(firestore, 'p1', activePlantingId: 'b');
      await seedPlanting(firestore, 'a', parcelId: 'p1', status: 'completed');
      await seedPlanting(firestore, 'b', parcelId: 'p1');
      await pumpDetail(tester, 'a');

      await tester.tap(find.byKey(PlantingKeys.statusSwitch));
      await tester.pumpAndSettle();

      expect((await plantingData('a'))['status'], 'completed');
      expect(
        find.text(
          'Na parceli već postoji aktivna sadnja. Prvo je označite kao završenu.',
        ),
        findsOneWidget,
      );
    });
  });
}
