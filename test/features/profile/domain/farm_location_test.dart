import 'package:agri_smart_guide/features/profile/domain/farm_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FarmLocation', () {
    const varazdin = FarmLocation(
      name: 'Varaždin',
      latitude: 46.3057,
      longitude: 16.3366,
    );

    test('pretvara se u Firestore mapu i natrag', () {
      expect(varazdin.toMap(), {
        'name': 'Varaždin',
        'latitude': 46.3057,
        'longitude': 16.3366,
      });
      expect(FarmLocation.fromMap(varazdin.toMap()), varazdin);
    });

    test('cijeli brojevi u koordinatama čitaju se kao decimalni', () {
      final location = FarmLocation.fromMap({
        'name': 'Ludbreg',
        'latitude': 46,
        'longitude': 17,
      });
      expect(location, isNotNull);
      expect(location!.latitude, 46.0);
      expect(location.longitude, 17.0);
    });

    test('vraća null kad lokacija nije odabrana ili je nepotpuna', () {
      expect(FarmLocation.fromMap({}), isNull);
      expect(FarmLocation.fromMap({'name': 'Zagreb'}), isNull);
      expect(
        FarmLocation.fromMap({
          'name': 'Zagreb',
          'latitude': '45.8',
          'longitude': 15.9,
        }),
        isNull,
      );
    });

    test('popis sadrži 20 sjedišta županija bez ponavljanja', () {
      final names = FarmLocation.croatianCities.map((city) => city.name);
      expect(names.length, 20);
      expect(names.toSet().length, 20);
      expect(names, containsAll(['Zagreb', 'Varaždin', 'Osijek', 'Split']));
    });

    test('koordinate su unutar Hrvatske', () {
      for (final city in FarmLocation.croatianCities) {
        expect(city.latitude, inInclusiveRange(42.0, 47.0), reason: city.name);
        expect(city.longitude, inInclusiveRange(13.0, 19.5), reason: city.name);
      }
    });
  });
}
