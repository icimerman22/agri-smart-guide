import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agri_smart_guide/features/crops/data/local_crop_data_source.dart';

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) async {
    if (key != 'assets/data/crop.json') {
      throw FlutterError('Neočekivana putanja: $key');
    }

    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCropDataSource', () {
    test('Učitava kulture iz stvarne JSON datoteke', () async {
      final file = File('assets/data/crop.json');

      expect(await file.exists(), isTrue);

      final content = await file.readAsString();

      final dataSource = LocalCropDataSource(bundle: _TestAssetBundle(content));

      final crops = await dataSource.loadCrops();

      expect(crops, isNotEmpty);
      expect(crops.length, greaterThanOrEqualTo(5));

      for (final crop in crops) {
        expect(crop.id.trim(), isNotEmpty);
        expect(crop.name.trim(), isNotEmpty);
        expect(crop.description.trim(), isNotEmpty);
        expect(crop.plantingPeriod.trim(), isNotEmpty);
        expect(crop.growingDurationDays, greaterThan(0));
      }

      final ids = crops.map((crop) => crop.id).toList();

      expect(ids.toSet().length, ids.length);
    });

    test('Odbacuje duplicirane identifikatore', () async {
      final crop = <String, dynamic>{
        'id': 'tomato',
        'name': 'Rajčica',
        'description': 'Povrtna kultura',
        'plantingPeriod': 'Proljeće',
        'growingConditions': 'Sunčan položaj',
        'growingDurationDays': 90,
        'waterNeeds': 'Redovito zalijevanje',
        'imagePath': null,
      };

      final content = jsonEncode([crop, crop]);

      final dataSource = LocalCropDataSource(bundle: _TestAssetBundle(content));

      await expectLater(
        dataSource.loadCrops(),
        throwsA(isA<FormatException>()),
      );
    });

    test('Prijavljuje pogrešku za neispravan JSON', () async {
      final dataSource = LocalCropDataSource(
        bundle: _TestAssetBundle('{neispravan JSON'),
      );

      await expectLater(
        dataSource.loadCrops(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
