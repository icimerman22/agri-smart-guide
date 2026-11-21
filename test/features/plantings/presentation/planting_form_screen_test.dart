import 'package:agri_smart_guide/features/auth/domain/auth_service.dart';
import 'package:agri_smart_guide/features/crops/data/local_crop_data_source.dart';
import 'package:agri_smart_guide/features/crops/domain/models/crop_model.dart';
import 'package:agri_smart_guide/features/plantings/data/firestore_planting_repository.dart';
import 'package:agri_smart_guide/features/plantings/domain/planting_repository.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_form_screen.dart';
import 'package:agri_smart_guide/features/plantings/presentation/planting_keys.dart';
import 'package:agri_smart_guide/features/plots/data/plot_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _ThrowingPlantingRepository implements PlantingRepository {
  @override
  Future<String> addPlanting({
    required String ownerId,
    required String parcelId,
    required String cropId,
    required DateTime plantedAt,
    required int growingDurationDays,
  }) async {
    throw const PlantingException(
      PlantingException.notParcelOwner,
      message: 'Sadnju možete evidentirati samo na vlastitoj parceli.',
    );
  }
}

void main() {
  final today = DateTime(2026, 5, 10);

  late FakeFirebaseFirestore firestore;
  late FakeAuthService auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = FakeAuthService(currentUser: const AuthUser(uid: 'alice'));
  });

  Future<void> openForm(
    WidgetTester tester, {
    PlantingRepository? plantingRepository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlantingFormScreen(
                      authService: auth,
                      plotRepository: PlotRepository(firestore: firestore),
                      plantingRepository:
                          plantingRepository ??
                          FirestorePlantingRepository(firestore: firestore),
                      cropDataSource: _FakeCropDataSource(),
                      today: () => today,
                    ),
                  ),
                ),
                child: const Text('Otvori'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseCrop(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(PlantingKeys.cropField));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> chooseParcel(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(PlantingKeys.parcelField));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> chooseTodayDate(WidgetTester tester) async {
    await tester.tap(find.byKey(PlantingKeys.dateField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String crop = 'Rajčica',
    String parcel = 'Njiva',
  }) async {
    await chooseCrop(tester, crop);
    await chooseParcel(tester, parcel);
    await chooseTodayDate(tester);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(PlantingKeys.save));
    await tester.tap(find.byKey(PlantingKeys.save));
    await tester.pumpAndSettle();
  }

  Future<int> plantingCount() async =>
      (await firestore.collection('plantings').get()).size;

  group('PlantingFormScreen prikaz', () {
    testWidgets('nudi kulture iz kataloga i samo vlastite parcele', (
      tester,
    ) async {
      await seedParcel(firestore, 'p1', name: 'Moja njiva');
      await seedParcel(firestore, 'p2', ownerId: 'bob', name: 'Tuđi vrt');
      await openForm(tester);

      await tester.tap(find.byKey(PlantingKeys.cropField));
      await tester.pumpAndSettle();
      expect(find.text('Rajčica'), findsWidgets);
      expect(find.text('Salata'), findsWidgets);
      await tester.tap(find.text('Rajčica').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PlantingKeys.parcelField));
      await tester.pumpAndSettle();
      expect(find.text('Moja njiva'), findsWidgets);
      expect(find.text('Tuđi vrt'), findsNothing);
    });

    testWidgets('bez parcela prikazuje poruku umjesto forme', (tester) async {
      await seedParcel(firestore, 'p2', ownerId: 'bob');
      await openForm(tester);

      expect(find.byKey(PlantingKeys.noParcels), findsOneWidget);
      expect(find.byKey(PlantingKeys.save), findsNothing);
    });

  });

  group('PlantingFormScreen validacija', () {
    testWidgets('prazna forma prikazuje sve greške i ne sprema', (tester) async {
      await seedParcel(firestore, 'p1');
      await openForm(tester);

      await save(tester);

      expect(find.text('Odaberite kulturu'), findsOneWidget);
      expect(find.text('Odaberite parcelu'), findsOneWidget);
      expect(find.text('Odaberite datum sadnje'), findsOneWidget);
      expect(await plantingCount(), 0);
      expect(find.byType(PlantingFormScreen), findsOneWidget);
    });

    testWidgets('odabrani datum prikazuje se u polju', (tester) async {
      await seedParcel(firestore, 'p1');
      await openForm(tester);

      await chooseTodayDate(tester);

      expect(find.text('10.05.2026'), findsOneWidget);
    });
  });

  group('PlantingFormScreen spremanje', () {
    testWidgets('sprema sadnju, prikazuje potvrdu i vraća na početni zaslon', (
      tester,
    ) async {
      await seedParcel(firestore, 'p1', name: 'Njiva');
      await openForm(tester);

      await fillForm(tester);
      await save(tester);

      final plantings = await firestore.collection('plantings').get();
      expect(plantings.size, 1);
      final data = plantings.docs.single.data();
      expect(data['ownerId'], 'alice');
      expect(data['cropId'], 'tomato');
      expect(data['parcelId'], 'p1');
      expect(data['status'], 'active');
      expect((data['plantedAt'] as Timestamp).toDate(), DateTime(2026, 5, 10));
      expect(
        (data['expectedHarvestAt'] as Timestamp).toDate(),
        DateTime(2026, 8, 8),
      );
      expect(
        find.text('Sadnja kulture Rajčica na parceli Njiva je evidentirana.'),
        findsOneWidget,
      );
      expect(find.byType(PlantingFormScreen), findsNothing);
      expect(find.text('Otvori'), findsOneWidget);
    });

    testWidgets('moguće je evidentirati više sadnji zaredom', (tester) async {
      await seedParcel(firestore, 'p1', name: 'Njiva');
      await seedParcel(firestore, 'p2', name: 'Vrt');

      await openForm(tester);
      await fillForm(tester, crop: 'Rajčica', parcel: 'Njiva');
      await save(tester);

      await tester.tap(find.text('Otvori'));
      await tester.pumpAndSettle();
      await fillForm(tester, crop: 'Salata', parcel: 'Vrt');
      await save(tester);

      expect(await plantingCount(), 2);
    });

    testWidgets('greška repozitorija prikazuje poruku i ostaje na formi', (
      tester,
    ) async {
      await seedParcel(firestore, 'p1', name: 'Njiva');
      await openForm(tester, plantingRepository: _ThrowingPlantingRepository());

      await fillForm(tester);
      await save(tester);

      expect(
        find.text('Sadnju možete evidentirati samo na vlastitoj parceli.'),
        findsOneWidget,
      );
      expect(find.byType(PlantingFormScreen), findsOneWidget);
    });
  });

  group('PlantingFormScreen zamjena aktivne sadnje', () {
    Future<void> prepare(WidgetTester tester) async {
      await seedPlanting(firestore, 'old', parcelId: 'p1');
      await seedParcel(
        firestore,
        'p1',
        name: 'Njiva',
        activePlantingId: 'old',
      );
      await openForm(tester);
      await fillForm(tester, crop: 'Salata');
      await save(tester);
      expect(find.text('Parcela već ima aktivnu sadnju'), findsOneWidget);
    }

    testWidgets('odustajanje ne mijenja ništa', (tester) async {
      await prepare(tester);

      await tester.tap(find.byKey(PlantingKeys.replaceCancel));
      await tester.pumpAndSettle();

      expect(await plantingCount(), 1);
      final old = (await firestore.doc('plantings/old').get()).data()!;
      expect(old['status'], 'active');
      final parcel = (await firestore.doc('parcels/p1').get()).data()!;
      expect(parcel['activePlantingId'], 'old');
      expect(find.byType(PlantingFormScreen), findsOneWidget);
    });

    testWidgets('potvrda zamjenjuje prethodnu sadnju novom', (tester) async {
      await prepare(tester);

      await tester.tap(find.byKey(PlantingKeys.replaceConfirm));
      await tester.pumpAndSettle();

      expect(await plantingCount(), 2);
      final old = (await firestore.doc('plantings/old').get()).data()!;
      expect(old['status'], 'completed');
      final parcel = (await firestore.doc('parcels/p1').get()).data()!;
      final newId = parcel['activePlantingId'] as String;
      expect(newId, isNot('old'));
      final created = (await firestore.doc('plantings/$newId').get()).data()!;
      expect(created['cropId'], 'lettuce');
      expect(created['status'], 'active');
      expect(find.byType(PlantingFormScreen), findsNothing);
    });
  });
}
