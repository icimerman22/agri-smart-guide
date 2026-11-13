import 'package:agri_smart_guide/features/profile/domain/farm_location.dart';
import 'package:agri_smart_guide/features/profile/presentation/location_picker.dart';
import 'package:agri_smart_guide/features/profile/presentation/profile_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/profile_test_helpers.dart';

void main() {
  Future<void> pumpPicker(WidgetTester tester, Widget picker) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: picker)));
  }

  group('LocationPicker', () {
    testWidgets('bez odabira prikazuje uputu', (tester) async {
      await pumpPicker(tester, LocationPicker(value: null, onChanged: (_) {}));

      expect(find.text('Odaberite lokaciju'), findsOneWidget);
    });

    testWidgets('javlja odabranu lokaciju', (tester) async {
      FarmLocation? selected;
      await pumpPicker(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LocationPicker(
            value: selected,
            onChanged: (location) => setState(() => selected = location),
          ),
        ),
      );
      await selectDropdownItem(tester, ProfileKeys.location, 'Varaždin');

      expect(selected?.name, 'Varaždin');
      expect(selected?.latitude, 46.3057);
      expect(find.text('Varaždin'), findsOneWidget);
    });

    testWidgets('spremljena lokacija izvan popisa ostaje vidljiva', (
      tester,
    ) async {
      const ludbreg = FarmLocation(
        name: 'Ludbreg',
        latitude: 46.25,
        longitude: 16.61,
      );
      await pumpPicker(
        tester,
        LocationPicker(value: ludbreg, onChanged: (_) {}),
      );

      expect(find.text('Ludbreg'), findsOneWidget);
    });
  });
}
