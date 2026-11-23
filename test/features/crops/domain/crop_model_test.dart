import 'package:flutter_test/flutter_test.dart';

import 'package:agri_smart_guide/features/crops/domain/models/crop_model.dart';

void main() {
  group('CropModel', () {
    test('Ispravno pretvara JSON u CropModel', () {
      final json = <String, dynamic>{
        'id': 'tomato',
        'name': 'Rajčica',
        'description': 'Povrtna kultura',
        'plantingPeriod': 'Proljeće',
        'growingConditions': 'Sunčan položaj',
        'growingDurationDays': 90,
        'waterNeeds': 'Redovito zalijevanje',
        'imagePath': null,
      };

      final crop = CropModel.fromJson(json);

      expect(crop.id, 'tomato');
      expect(crop.name, 'Rajčica');
      expect(crop.description, 'Povrtna kultura');
      expect(crop.plantingPeriod, 'Proljeće');
      expect(crop.growingConditions, 'Sunčan položaj');
      expect(crop.growingDurationDays, 90);
      expect(crop.waterNeeds, 'Redovito zalijevanje');
      expect(crop.imagePath, isNull);
    });

    test('Ne prihvaća pogrešan tip podatka', () {
      final json = <String, dynamic>{
        'id': 'tomato',
        'name': 'Rajčica',
        'description': 'Povrtna kultura',
        'plantingPeriod': 'Proljeće',
        'growingConditions': 'Sunčan položaj',
        'growingDurationDays': 'devedeset',
        'waterNeeds': 'Redovito zalijevanje',
        'imagePath': null,
      };

      expect(() => CropModel.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
