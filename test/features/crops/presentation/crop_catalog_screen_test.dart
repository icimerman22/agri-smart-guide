import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agri_smart_guide/features/crops/data/local_crop_data_source.dart';
import 'package:agri_smart_guide/features/crops/domain/models/crop_model.dart';
import 'package:agri_smart_guide/features/crops/presentation/crop_catalog_screen.dart';

class _FakeCropDataSource extends LocalCropDataSource {
  @override
  Future<List<CropModel>> loadCrops() async {
    return [
      const CropModel(
        id: 'tomato',
        name: 'Rajčica',
        description: 'Povrtna kultura',
        plantingPeriod: 'Proljeće',
        growingConditions: 'Sunčan položaj',
        growingDurationDays: 90,
        waterNeeds: 'Redovito zalijevanje',
      ),
      const CropModel(
        id: 'pepper',
        name: 'Paprika',
        description: 'Toploljubiva kultura',
        plantingPeriod: 'Proljeće',
        growingConditions: 'Topao položaj',
        growingDurationDays: 100,
        waterNeeds: 'Umjereno zalijevanje',
      ),
    ];
  }
}

class _EmptyCropDataSource extends LocalCropDataSource {
  @override
  Future<List<CropModel>> loadCrops() async {
    return [];
  }
}

class _FailingCropDataSource extends LocalCropDataSource {
  @override
  Future<List<CropModel>> loadCrops() async {
    throw StateError('Testna pogreška');
  }
}

void main() {
  Widget createApp(LocalCropDataSource dataSource) {
    return MaterialApp(home: CropCatalogScreen(dataSource: dataSource));
  }

  testWidgets('Prikazuje dostupne kulture', (tester) async {
    await tester.pumpWidget(createApp(_FakeCropDataSource()));
    await tester.pumpAndSettle();

    expect(find.text('Katalog kultura'), findsOneWidget);
    expect(find.text('Rajčica'), findsOneWidget);
    expect(find.text('Paprika'), findsOneWidget);
  });

  testWidgets('Pretraživanje filtrira kulture', (tester) async {
    await tester.pumpWidget(createApp(_FakeCropDataSource()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'paprika');

    await tester.pumpAndSettle();

    expect(find.text('Paprika'), findsOneWidget);
    expect(find.text('Rajčica'), findsNothing);
  });

  testWidgets('Otvara detalje odabrane kulture', (tester) async {
    await tester.pumpWidget(createApp(_FakeCropDataSource()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rajčica'));
    await tester.pumpAndSettle();

    expect(find.text('Preporučeno razdoblje sadnje'), findsOneWidget);

    expect(find.text('Uvjeti uzgoja'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Katalog kultura'), findsOneWidget);
  });

  testWidgets('Prikazuje poruku kada nema rezultata', (tester) async {
    await tester.pumpWidget(createApp(_FakeCropDataSource()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nepostojeca kultura');

    await tester.pumpAndSettle();

    expect(find.text('Nema rezultata za ovu pretragu.'), findsOneWidget);
  });

  testWidgets('Prikazuje poruku za prazan katalog', (tester) async {
    await tester.pumpWidget(createApp(_EmptyCropDataSource()));
    await tester.pumpAndSettle();

    expect(find.text('Nema dostupnih kultura.'), findsOneWidget);
  });

  testWidgets('Prikazuje pogrešku pri učitavanju', (tester) async {
    await tester.pumpWidget(createApp(_FailingCropDataSource()));
    await tester.pumpAndSettle();

    expect(find.text('Nije moguće učitati katalog kultura.'), findsOneWidget);

    expect(find.text('Pokušaj ponovno'), findsOneWidget);
  });
}
