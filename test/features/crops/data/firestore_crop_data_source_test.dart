import 'package:agri_smart_guide/features/crops/data/firestore_crop_data_source.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreCropDataSource dataSource;

  Map<String, dynamic> cropData({
    required String name,
    int? sortOrder,
    int growthDays = 90,
    bool includeOptionalFields = true,
  }) {
    return {
      'name': name,
      'category': 'povrće',
      'description': 'Opis kulture',
      'sowingMonths': [3, 4],
      'growthDays': growthDays,
      'waterRequirement': 'Umjereno zalijevanje',
      'rowSpacingCm': 70,
      'plantSpacingCm': 30.5,
      'optimalPhMin': 6,
      'optimalPhMax': 7.5,
      if (includeOptionalFields) ...{
        'plantingPeriod': 'Proljeće',
        'growingConditions': 'Sunčan položaj',
        'imageUrl': 'https://example.com/crop.png',
      },
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();

    dataSource = FirestoreCropDataSource(firestore: firestore);
  });

  group('FirestoreCropDataSource', () {
    test('dohvaća kulture iz kolekcije crops', () async {
      await firestore
          .collection('crops')
          .doc('sunflower')
          .set(cropData(name: 'Suncokret', sortOrder: 1, growthDays: 110));

      await firestore
          .collection('plantings')
          .doc('other')
          .set(cropData(name: 'Nepovezana kultura'));

      final crops = await dataSource.loadCrops();

      expect(crops, hasLength(1));
      expect(crops.first, isA<Crop>());
      expect(crops.first.id, 'sunflower');
      expect(crops.first.name, 'Suncokret');
    });

    test('ispravno pretvara Firestore polja u Crop', () async {
      await firestore
          .collection('crops')
          .doc('tomato')
          .set(cropData(name: 'Rajčica', sortOrder: 2, growthDays: 90));

      final crops = await dataSource.loadCrops();
      final crop = crops.single;

      expect(crop.id, 'tomato');
      expect(crop.name, 'Rajčica');
      expect(crop.category, 'povrće');
      expect(crop.description, 'Opis kulture');

      expect(crop.sowingMonths, [3, 4]);
      expect(crop.growthDays, 90);
      expect(crop.waterRequirement, 'Umjereno zalijevanje');

      expect(crop.rowSpacingCm, 70.0);
      expect(crop.plantSpacingCm, 30.5);
      expect(crop.optimalPhMin, 6.0);
      expect(crop.optimalPhMax, 7.5);

      expect(crop.plantingPeriod, 'Proljeće');
      expect(crop.growingConditions, 'Sunčan položaj');
      expect(crop.imageUrl, 'https://example.com/crop.png');
      expect(crop.sortOrder, 2);
    });

    test('sortira kulture prema sortOrder', () async {
      await firestore
          .collection('crops')
          .doc('sunflower')
          .set(cropData(name: 'Suncokret', sortOrder: 3));

      await firestore
          .collection('crops')
          .doc('tomato')
          .set(cropData(name: 'Rajčica', sortOrder: 1));

      await firestore
          .collection('crops')
          .doc('lettuce')
          .set(cropData(name: 'Salata', sortOrder: 2));

      final crops = await dataSource.loadCrops();

      expect(crops.map((crop) => crop.id).toList(), [
        'tomato',
        'lettuce',
        'sunflower',
      ]);
    });

    test('kulture bez sortOrder dolaze nakon ostalih '
        'i sortiraju se po nazivu', () async {
      await firestore
          .collection('crops')
          .doc('pepper')
          .set(cropData(name: 'Paprika'));

      await firestore
          .collection('crops')
          .doc('carrot')
          .set(cropData(name: 'Mrkva'));

      await firestore
          .collection('crops')
          .doc('tomato')
          .set(cropData(name: 'Rajčica', sortOrder: 1));

      final crops = await dataSource.loadCrops();

      expect(crops.map((crop) => crop.id).toList(), [
        'tomato',
        'carrot',
        'pepper',
      ]);
    });

    test('prihvaća dokument bez neobaveznih polja', () async {
      await firestore
          .collection('crops')
          .doc('potato')
          .set(cropData(name: 'Krumpir', includeOptionalFields: false));

      final crops = await dataSource.loadCrops();
      final crop = crops.single;

      expect(crop.name, 'Krumpir');
      expect(crop.growthDays, 90);

      expect(crop.plantingPeriod, isNull);
      expect(crop.growingConditions, isNull);
      expect(crop.imageUrl, isNull);
      expect(crop.sortOrder, isNull);
    });

    test('vraća prazan popis kada nema kultura', () async {
      final crops = await dataSource.loadCrops();

      expect(crops, isEmpty);
    });

    test('prijavljuje pogrešku za neispravan dokument', () async {
      final invalidData = cropData(name: 'Neispravna kultura');

      invalidData['growthDays'] = 'devedeset';

      await firestore.collection('crops').doc('invalid').set(invalidData);

      await expectLater(dataSource.loadCrops(), throwsA(isA<Object>()));
    });
  });
}
