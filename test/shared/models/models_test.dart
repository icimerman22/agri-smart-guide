import 'package:agri_smart_guide/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    Map<String, dynamic> fixture() => {
      'firstName': 'value',
      'lastName': 'value',
      'farmName': 'value',
      'primaryLocation': <String, dynamic>{
        'enabled': true,
        'nested': <String, dynamic>{'name': 'Zagreb'},
      },
      'unitSystem': 'value',
      'notificationSettings': <String, dynamic>{
        'enabled': true,
        'nested': <String, dynamic>{'name': 'Zagreb'},
      },
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = UserProfile.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'firstName',
        'lastName',
        'farmName',
        'primaryLocation',
        'unitSystem',
        'notificationSettings',
        'createdAt',
        'updatedAt',
      ]) {
        expect(
          () => UserProfile.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => UserProfile.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => UserProfile.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
  });
  group('Parcel', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'name': 'value',
      'areaHa': 2.5,
      'soilType': 'value',
      'locationName': 'value',
      'coordinates': const GeoPoint(45.8, 16.0),
      'activePlantingId': 'value',
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = Parcel.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'name',
        'areaHa',
        'soilType',
        'locationName',
        'coordinates',
        'createdAt',
        'updatedAt',
      ]) {
        expect(
          () => Parcel.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => Parcel.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => Parcel.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('areaHa accepts integer Firestore numbers', () {
      expect(Parcel.fromMap('id', fixture()..['areaHa'] = 2).areaHa, 2.0);
    });
    test('activePlantingId accepts absent and null but rejects wrong type', () {
      expect(
        Parcel.fromMap(
          'id',
          fixture()..remove('activePlantingId'),
        ).activePlantingId,
        isNull,
      );
      expect(
        Parcel.fromMap(
          'id',
          fixture()..['activePlantingId'] = null,
        ).toMap()['activePlantingId'],
        isNull,
      );
      expect(
        () => Parcel.fromMap('id', fixture()..['activePlantingId'] = Object()),
        throwsFormatException,
      );
    });
  });
  group('Crop', () {
    Map<String, dynamic> fixture() => {
      'name': 'value',
      'category': 'value',
      'description': 'value',
      'sowingMonths': <int>[3, 4],
      'growthDays': 2027,
      'waterRequirement': 'value',
      'rowSpacingCm': 2.5,
      'plantSpacingCm': 2.5,
      'optimalPhMin': 2.5,
      'optimalPhMax': 2.5,
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = Crop.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'name',
        'category',
        'description',
        'sowingMonths',
        'growthDays',
        'waterRequirement',
        'rowSpacingCm',
        'plantSpacingCm',
        'optimalPhMin',
        'optimalPhMax',
      ]) {
        expect(
          () => Crop.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => Crop.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => Crop.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('sowingMonths rejects invalid elements and cannot be mutated', () {
      expect(
        () => Crop.fromMap('id', fixture()..['sowingMonths'] = [false]),
        throwsFormatException,
      );
      expect(
        () => Crop.fromMap('id', fixture()).sowingMonths.clear(),
        throwsUnsupportedError,
      );
    });
    test('rowSpacingCm accepts integer Firestore numbers', () {
      expect(
        Crop.fromMap('id', fixture()..['rowSpacingCm'] = 2).rowSpacingCm,
        2.0,
      );
    });
    test('plantSpacingCm accepts integer Firestore numbers', () {
      expect(
        Crop.fromMap('id', fixture()..['plantSpacingCm'] = 2).plantSpacingCm,
        2.0,
      );
    });
    test('optimalPhMin accepts integer Firestore numbers', () {
      expect(
        Crop.fromMap('id', fixture()..['optimalPhMin'] = 2).optimalPhMin,
        2.0,
      );
    });
    test('optimalPhMax accepts integer Firestore numbers', () {
      expect(
        Crop.fromMap('id', fixture()..['optimalPhMax'] = 2).optimalPhMax,
        2.0,
      );
    });
  });
  group('Planting', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'cropId': 'value',
      'plantedAt': Timestamp(1700000000, 123456789),
      'expectedHarvestAt': Timestamp(1700000000, 123456789),
      'stage': 'value',
      'status': 'value',
      'seasonYear': 2027,
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = Planting.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
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
      ]) {
        expect(
          () => Planting.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => Planting.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => Planting.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
  });
  group('FarmTask', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'title': 'value',
      'description': 'value',
      'type': 'value',
      'dueAt': Timestamp(1700000000, 123456789),
      'priority': 'value',
      'status': 'value',
      'completedAt': Timestamp(1700000000, 123456789),
      'costCents': 2027,
      'costCategory': 'value',
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = FarmTask.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'title',
        'description',
        'type',
        'dueAt',
        'priority',
        'status',
        'createdAt',
        'updatedAt',
      ]) {
        expect(
          () => FarmTask.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => FarmTask.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => FarmTask.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('parcelId accepts absent and null but rejects wrong type', () {
      expect(
        FarmTask.fromMap('id', fixture()..remove('parcelId')).parcelId,
        isNull,
      );
      expect(
        FarmTask.fromMap(
          'id',
          fixture()..['parcelId'] = null,
        ).toMap()['parcelId'],
        isNull,
      );
      expect(
        () => FarmTask.fromMap('id', fixture()..['parcelId'] = Object()),
        throwsFormatException,
      );
    });
    test('completedAt accepts absent and null but rejects wrong type', () {
      expect(
        FarmTask.fromMap('id', fixture()..remove('completedAt')).completedAt,
        isNull,
      );
      expect(
        FarmTask.fromMap(
          'id',
          fixture()..['completedAt'] = null,
        ).toMap()['completedAt'],
        isNull,
      );
      expect(
        () => FarmTask.fromMap('id', fixture()..['completedAt'] = Object()),
        throwsFormatException,
      );
    });
    test('costCents accepts absent and null but rejects wrong type', () {
      expect(
        FarmTask.fromMap('id', fixture()..remove('costCents')).costCents,
        isNull,
      );
      expect(
        FarmTask.fromMap(
          'id',
          fixture()..['costCents'] = null,
        ).toMap()['costCents'],
        isNull,
      );
      expect(
        () => FarmTask.fromMap('id', fixture()..['costCents'] = Object()),
        throwsFormatException,
      );
    });
    test('costCategory accepts absent and null but rejects wrong type', () {
      expect(
        FarmTask.fromMap('id', fixture()..remove('costCategory')).costCategory,
        isNull,
      );
      expect(
        FarmTask.fromMap(
          'id',
          fixture()..['costCategory'] = null,
        ).toMap()['costCategory'],
        isNull,
      );
      expect(
        () => FarmTask.fromMap('id', fixture()..['costCategory'] = Object()),
        throwsFormatException,
      );
    });
  });
  group('SoilAnalysis', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'sampledAt': Timestamp(1700000000, 123456789),
      'ph': 2.5,
      'humusPercent': 2.5,
      'nitrogenPercent': 2.5,
      'phosphorusMgPer100g': 2.5,
      'potassiumMgPer100g': 2.5,
      'moisturePercent': 2.5,
      'createdAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = SoilAnalysis.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'parcelId',
        'sampledAt',
        'ph',
        'humusPercent',
        'nitrogenPercent',
        'phosphorusMgPer100g',
        'potassiumMgPer100g',
        'createdAt',
      ]) {
        expect(
          () => SoilAnalysis.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => SoilAnalysis.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => SoilAnalysis.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('ph accepts integer Firestore numbers', () {
      expect(SoilAnalysis.fromMap('id', fixture()..['ph'] = 2).ph, 2.0);
    });
    test('humusPercent accepts integer Firestore numbers', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['humusPercent'] = 2,
        ).humusPercent,
        2.0,
      );
    });
    test('nitrogenPercent accepts integer Firestore numbers', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['nitrogenPercent'] = 2,
        ).nitrogenPercent,
        2.0,
      );
    });
    test('phosphorusMgPer100g accepts integer Firestore numbers', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['phosphorusMgPer100g'] = 2,
        ).phosphorusMgPer100g,
        2.0,
      );
    });
    test('potassiumMgPer100g accepts integer Firestore numbers', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['potassiumMgPer100g'] = 2,
        ).potassiumMgPer100g,
        2.0,
      );
    });
    test('moisturePercent accepts absent and null but rejects wrong type', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..remove('moisturePercent'),
        ).moisturePercent,
        isNull,
      );
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['moisturePercent'] = null,
        ).toMap()['moisturePercent'],
        isNull,
      );
      expect(
        () => SoilAnalysis.fromMap(
          'id',
          fixture()..['moisturePercent'] = Object(),
        ),
        throwsFormatException,
      );
    });
    test('moisturePercent accepts integer Firestore numbers', () {
      expect(
        SoilAnalysis.fromMap(
          'id',
          fixture()..['moisturePercent'] = 2,
        ).moisturePercent,
        2.0,
      );
    });
  });
  group('VegetationRecord', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'measuredAt': Timestamp(1700000000, 123456789),
      'ndvi': 2.5,
      'healthStatus': 'value',
      'summary': 'value',
      'visualizationAssetPath': 'value',
      'isDemo': true,
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = VegetationRecord.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'parcelId',
        'measuredAt',
        'ndvi',
        'healthStatus',
        'summary',
        'isDemo',
      ]) {
        expect(
          () => VegetationRecord.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => VegetationRecord.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => VegetationRecord.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('ndvi accepts integer Firestore numbers', () {
      expect(VegetationRecord.fromMap('id', fixture()..['ndvi'] = 2).ndvi, 2.0);
    });
    test(
      'visualizationAssetPath accepts absent and null but rejects wrong type',
      () {
        expect(
          VegetationRecord.fromMap(
            'id',
            fixture()..remove('visualizationAssetPath'),
          ).visualizationAssetPath,
          isNull,
        );
        expect(
          VegetationRecord.fromMap(
            'id',
            fixture()..['visualizationAssetPath'] = null,
          ).toMap()['visualizationAssetPath'],
          isNull,
        );
        expect(
          () => VegetationRecord.fromMap(
            'id',
            fixture()..['visualizationAssetPath'] = Object(),
          ),
          throwsFormatException,
        );
      },
    );
  });
  group('Note', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'title': 'value',
      'content': 'value',
      'photoPaths': <String>['photos/a.jpg'],
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = Note.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'title',
        'content',
        'photoPaths',
        'createdAt',
        'updatedAt',
      ]) {
        expect(
          () => Note.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => Note.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => Note.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('parcelId accepts absent and null but rejects wrong type', () {
      expect(
        Note.fromMap('id', fixture()..remove('parcelId')).parcelId,
        isNull,
      );
      expect(
        Note.fromMap('id', fixture()..['parcelId'] = null).toMap()['parcelId'],
        isNull,
      );
      expect(
        () => Note.fromMap('id', fixture()..['parcelId'] = Object()),
        throwsFormatException,
      );
    });
    test('photoPaths rejects invalid elements and cannot be mutated', () {
      expect(
        () => Note.fromMap('id', fixture()..['photoPaths'] = [false]),
        throwsFormatException,
      );
      expect(
        () => Note.fromMap('id', fixture()).photoPaths.clear(),
        throwsUnsupportedError,
      );
    });
  });
  group('Harvest', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'plantingId': 'value',
      'harvestedAt': Timestamp(1700000000, 123456789),
      'quantityKg': 2.5,
      'areaHaAtHarvest': 2.5,
      'note': 'value',
      'createdAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = Harvest.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'parcelId',
        'plantingId',
        'harvestedAt',
        'quantityKg',
        'areaHaAtHarvest',
        'note',
        'createdAt',
      ]) {
        expect(
          () => Harvest.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => Harvest.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => Harvest.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('quantityKg accepts integer Firestore numbers', () {
      expect(
        Harvest.fromMap('id', fixture()..['quantityKg'] = 2).quantityKg,
        2.0,
      );
    });
    test('areaHaAtHarvest accepts integer Firestore numbers', () {
      expect(
        Harvest.fromMap(
          'id',
          fixture()..['areaHaAtHarvest'] = 2,
        ).areaHaAtHarvest,
        2.0,
      );
    });
  });
  group('AppNotification', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'type': 'value',
      'title': 'value',
      'body': 'value',
      'relatedEntityType': 'value',
      'relatedEntityId': 'value',
      'createdAt': Timestamp(1700000000, 123456789),
      'readAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = AppNotification.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'type',
        'title',
        'body',
        'relatedEntityType',
        'relatedEntityId',
        'createdAt',
      ]) {
        expect(
          () => AppNotification.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => AppNotification.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => AppNotification.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
    test('readAt accepts absent and null but rejects wrong type', () {
      expect(
        AppNotification.fromMap('id', fixture()..remove('readAt')).readAt,
        isNull,
      );
      expect(
        AppNotification.fromMap(
          'id',
          fixture()..['readAt'] = null,
        ).toMap()['readAt'],
        isNull,
      );
      expect(
        () => AppNotification.fromMap('id', fixture()..['readAt'] = Object()),
        throwsFormatException,
      );
    });
  });
  group('RotationPlan', () {
    Map<String, dynamic> fixture() => {
      'ownerId': 'value',
      'parcelId': 'value',
      'seasonYear': 2027,
      'cropId': 'value',
      'createdAt': Timestamp(1700000000, 123456789),
      'updatedAt': Timestamp(1700000000, 123456789),
    };
    test('round trip preserves schema, values and timestamp precision', () {
      final data = fixture();
      final model = RotationPlan.fromMap('document-id', data);
      expect(model.id, 'document-id');
      expect(model.toMap(), data);
      expect(model.toMap().containsKey('id'), isFalse);
    });
    test('required fields reject missing, null and wrong types', () {
      for (final key in <String>[
        'ownerId',
        'parcelId',
        'seasonYear',
        'cropId',
        'createdAt',
        'updatedAt',
      ]) {
        expect(
          () => RotationPlan.fromMap('id', fixture()..remove(key)),
          throwsFormatException,
        );
        expect(
          () => RotationPlan.fromMap('id', fixture()..[key] = null),
          throwsFormatException,
        );
        expect(
          () => RotationPlan.fromMap('id', fixture()..[key] = Object()),
          throwsFormatException,
        );
      }
    });
  });
  test('rotation document IDs use parcel and season', () {
    expect(RotationPlan.documentId('parcel123', 2027), 'parcel123_2027');
  });
  test('profile maps are deep copied and immutable', () {
    final location = <String, dynamic>{
      'nested': <String, dynamic>{'name': 'Zagreb'},
    };
    final profile = UserProfile(
      id: 'u',
      firstName: 'A',
      lastName: 'B',
      farmName: 'F',
      primaryLocation: location,
      unitSystem: 'metric',
      notificationSettings: {},
      createdAt: Timestamp(1, 0),
      updatedAt: Timestamp(1, 0),
    );
    (location['nested'] as Map)['name'] = 'changed';
    expect(profile.primaryLocation['nested']['name'], 'Zagreb');
    expect(
      () => profile.primaryLocation['nested']['name'] = 'changed',
      throwsUnsupportedError,
    );
  });
}
