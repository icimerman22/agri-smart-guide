import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agri_smart_guide/shared/models/crop.dart';
import 'package:agri_smart_guide/features/crops/data/crop_catalog_data_source.dart';
import 'package:agri_smart_guide/features/crops/presentation/crop_catalog_screen.dart';

class _FakeCropDataSource implements CropCatalogDataSource {
  @override
  Future<List<Crop>> loadCrops() async {
    return [
      Crop(
        id: 'tomato',
        name: 'Rajčica',
        category: 'Povrće',
        description: 'Povrtna kultura',
        sowingMonths: [4, 5],
        growthDays: 90,
        waterRequirement: 'Redovito zalijevanje',
        rowSpacingCm: 70.0,
        plantSpacingCm: 40.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: 'Proljeće',
        growingConditions: 'Sunčan položaj',
      ),
      Crop(
        id: 'pepper',
        name: 'Paprika',
        category: 'Povrće',
        description: 'Toploljubiva kultura',
        sowingMonths: [4, 5],
        growthDays: 100,
        waterRequirement: 'Umjereno zalijevanje',
        rowSpacingCm: 60.0,
        plantSpacingCm: 40.0,
        optimalPhMin: 6.0,
        optimalPhMax: 7.0,
        plantingPeriod: 'Proljeće',
        growingConditions: 'Topao položaj',
      ),
    ];
  }
}

class _EmptyCropDataSource implements CropCatalogDataSource {
  @override
  Future<List<Crop>> loadCrops() async {
    return [];
  }
}

class _FailingCropDataSource implements CropCatalogDataSource {
  @override
  Future<List<Crop>> loadCrops() async {
    throw StateError('Testna pogreška');
  }
}

void main() {
  Widget createApp(CropCatalogDataSource dataSource) {
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
