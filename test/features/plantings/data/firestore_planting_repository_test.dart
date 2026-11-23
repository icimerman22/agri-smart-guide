import 'package:agri_smart_guide/features/plantings/data/firestore_planting_repository.dart';
import 'package:agri_smart_guide/features/plantings/domain/planting_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/planting_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePlantingRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestorePlantingRepository(firestore: firestore);
  });

  Future<String> plant({
    String ownerId = 'alice',
    String parcelId = 'p1',
    String cropId = 'tomato',
    DateTime? plantedAt,
  }) {
    return repository.addPlanting(
      ownerId: ownerId,
      parcelId: parcelId,
      cropId: cropId,
      plantedAt: plantedAt ?? DateTime(2026, 5, 10),
      growingDurationDays: 90,
    );
  }

  Future<Map<String, dynamic>> plantingData(String id) async {
    return (await firestore.doc('plantings/$id').get()).data()!;
  }

  Future<String?> activePlantingOf(String parcelId) async {
    final data = (await firestore.doc('parcels/$parcelId').get()).data()!;
    return data['activePlantingId'] as String?;
  }

  Future<int> plantingCount() async =>
      (await firestore.collection('plantings').get()).size;

  Matcher plantingError(String code) => throwsA(
    isA<PlantingException>().having((error) => error.code, 'code', code),
  );

  group('FirestorePlantingRepository.addPlanting', () {
    test('zapisuje aktivnu sadnju s poljima koja traže pravila', () async {
      await seedParcel(firestore, 'p1');

      final id = await plant(cropId: 'pepper');
      final data = await plantingData(id);

      expect(data.keys.toSet(), {
        'ownerId',
        'parcelId',
        'cropId',
        'plantedAt',
        'expectedHarvestAt',
        'stage',
        'status',
        'seasonYear',
        'createdAt',
        'updatedAt',
      });
      expect(data['ownerId'], 'alice');
      expect(data['parcelId'], 'p1');
      expect(data['cropId'], 'pepper');
      expect(data['stage'], 'planted');
      expect(data['status'], 'active');
      expect(await activePlantingOf('p1'), id);
    });

    test('datumi: bez vremena, berba nakon trajanja uzgoja, godina sezone', () async {
      await seedParcel(firestore, 'p1');

      final id = await plant(plantedAt: DateTime(2025, 12, 20, 17, 45));
      final data = await plantingData(id);

      expect((data['plantedAt'] as Timestamp).toDate(), DateTime(2025, 12, 20));
      expect(
        (data['expectedHarvestAt'] as Timestamp).toDate(),
        DateTime(2026, 3, 20),
      );
      expect(data['seasonYear'], 2025);
    });

    test('dopušta više sadnji na različitim parcelama', () async {
      await seedParcel(firestore, 'p1');
      await seedParcel(firestore, 'p2');

      final first = await plant(parcelId: 'p1', cropId: 'tomato');
      final second = await plant(parcelId: 'p2', cropId: 'carrot');

      expect(first, isNot(second));
      expect(await activePlantingOf('p1'), first);
      expect(await activePlantingOf('p2'), second);
      expect((await plantingData(first))['status'], 'active');
      expect((await plantingData(second))['status'], 'active');
    });

    test('nova sadnja na istoj parceli završava prethodnu', () async {
      await seedParcel(firestore, 'p1');
      await seedParcel(firestore, 'p2');
      final other = await plant(parcelId: 'p2');

      final first = await plant(cropId: 'tomato');
      final second = await plant(cropId: 'lettuce');

      expect(await activePlantingOf('p1'), second);
      expect((await plantingData(first))['status'], 'completed');
      expect((await plantingData(second))['status'], 'active');
      expect((await plantingData(other))['status'], 'active');
    });

    test('već završena prethodna sadnja ostaje nepromijenjena', () async {
      await seedPlanting(firestore, 'old', status: 'completed');
      await seedParcel(firestore, 'p1', activePlantingId: 'old');
      final before = await plantingData('old');

      await plant();

      expect(await plantingData('old'), before);
    });

    test('radi kad parcela pokazuje na obrisanu sadnju', () async {
      await seedParcel(firestore, 'p1', activePlantingId: 'missing');

      final id = await plant();

      expect(await activePlantingOf('p1'), id);
    });

    test('odbija tuđu parcelu i ne mijenja ništa', () async {
      await seedPlanting(firestore, 'old', ownerId: 'bob');
      await seedParcel(
        firestore,
        'p1',
        ownerId: 'bob',
        activePlantingId: 'old',
      );

      await expectLater(
        plant(ownerId: 'alice'),
        plantingError(PlantingException.notParcelOwner),
      );

      expect(await plantingCount(), 1);
      expect((await plantingData('old'))['status'], 'active');
      expect(await activePlantingOf('p1'), 'old');
    });

    test('odbija nepostojeću parcelu', () async {
      await expectLater(
        plant(parcelId: 'missing'),
        plantingError(PlantingException.parcelNotFound),
      );

      expect(await plantingCount(), 0);
    });
  });

  group('FirestorePlantingRepository.updateStage', () {
    test('sprema novu fazu i osvježava updatedAt', () async {
      final clock = DateTime(2026, 6, 1, 12);
      repository = FirestorePlantingRepository(
        firestore: firestore,
        clock: () => clock,
      );
      await seedParcel(firestore, 'p1', activePlantingId: 'a');
      await seedPlanting(firestore, 'a', parcelId: 'p1');

      await repository.updateStage(
        ownerId: 'alice',
        plantingId: 'a',
        stage: 'flowering',
      );

      final data = await plantingData('a');
      expect(data['stage'], 'flowering');
      expect((data['updatedAt'] as Timestamp).toDate(), clock);
      expect(data['status'], 'active');
    });

    test('odbija tuđu sadnju', () async {
      await seedPlanting(firestore, 'a', ownerId: 'bob');

      await expectLater(
        repository.updateStage(
          ownerId: 'alice',
          plantingId: 'a',
          stage: 'growth',
        ),
        plantingError(PlantingException.notPlantingOwner),
      );

      expect((await plantingData('a'))['stage'], 'planted');
    });
  });

  group('FirestorePlantingRepository.updateStatus', () {
    test('završetak sadnje oslobađa parcelu', () async {
      await seedParcel(firestore, 'p1', activePlantingId: 'a');
      await seedPlanting(firestore, 'a', parcelId: 'p1');

      await repository.updateStatus(
        ownerId: 'alice',
        plantingId: 'a',
        status: 'completed',
      );

      expect((await plantingData('a'))['status'], 'completed');
      expect(await activePlantingOf('p1'), isNull);
    });

    test('ponovna aktivacija odbijena ako parcela ima aktivnu sadnju', () async {
      await seedParcel(firestore, 'p1', activePlantingId: 'b');
      await seedPlanting(firestore, 'a', parcelId: 'p1', status: 'completed');
      await seedPlanting(firestore, 'b', parcelId: 'p1');

      await expectLater(
        repository.updateStatus(
          ownerId: 'alice',
          plantingId: 'a',
          status: 'active',
        ),
        plantingError(PlantingException.parcelOccupied),
      );

      expect((await plantingData('a'))['status'], 'completed');
      expect(await activePlantingOf('p1'), 'b');
    });

    test('odbija tuđu sadnju i ne mijenja parcelu', () async {
      await seedParcel(firestore, 'p1', ownerId: 'bob', activePlantingId: 'a');
      await seedPlanting(firestore, 'a', ownerId: 'bob', parcelId: 'p1');

      await expectLater(
        repository.updateStatus(
          ownerId: 'alice',
          plantingId: 'a',
          status: 'completed',
        ),
        plantingError(PlantingException.notPlantingOwner),
      );

      expect((await plantingData('a'))['status'], 'active');
      expect(await activePlantingOf('p1'), 'a');
    });
  });

  group('FirestorePlantingRepository čitanje', () {
    test('watchPlantings vraća samo sadnje vlasnika', () async {
      await seedPlanting(firestore, 'a');
      await seedPlanting(firestore, 'b', ownerId: 'bob');
      await seedPlanting(firestore, 'c');

      final plantings = await repository.watchPlantings('alice').first;

      expect(plantings.map((p) => p.id).toSet(), {'a', 'c'});
    });
  });
}
