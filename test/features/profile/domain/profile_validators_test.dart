import 'package:agri_smart_guide/features/profile/domain/profile_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileValidators.firstName i lastName', () {
    test('vraća grešku za prazan unos', () {
      expect(ProfileValidators.firstName(null), 'Molimo unesite ime.');
      expect(ProfileValidators.firstName(''), 'Molimo unesite ime.');
      expect(ProfileValidators.firstName('   '), 'Molimo unesite ime.');
      expect(ProfileValidators.lastName(''), 'Molimo unesite prezime.');
    });

    test('prihvaća hrvatska slova, razmak, crticu i apostrof', () {
      for (final input in [
        'Ana',
        'Đurđica',
        'Ana Marija',
        'Ana-Marija',
        "O'Brien",
        'Šimić-Čačić',
        '  Ivan  ',
      ]) {
        expect(ProfileValidators.firstName(input), isNull, reason: input);
        expect(ProfileValidators.lastName(input), isNull, reason: input);
      }
    });

    test('odbija brojeve i posebne znakove', () {
      for (final input in ['Ana1', 'Ivan!', '-Ana', 'Ana_Marija', '@']) {
        expect(
          ProfileValidators.firstName(input),
          'Ime smije sadržavati samo slova, razmake, crticu i apostrof.',
          reason: input,
        );
      }
      expect(
        ProfileValidators.lastName('Horvat2'),
        'Prezime smije sadržavati samo slova, razmake, crticu i apostrof.',
      );
    });

    test('odbija predug unos', () {
      final maxLength = 'a' * ProfileValidators.maxNameLength;
      expect(ProfileValidators.firstName(maxLength), isNull);
      expect(
        ProfileValidators.firstName('${maxLength}a'),
        'Ime može imati najviše 50 znakova.',
      );
      expect(
        ProfileValidators.lastName('${maxLength}a'),
        'Prezime može imati najviše 50 znakova.',
      );
    });
  });

  group('ProfileValidators.farmName', () {
    test('naziv gospodarstva nije obavezan', () {
      expect(ProfileValidators.farmName(null), isNull);
      expect(ProfileValidators.farmName(''), isNull);
      expect(ProfileValidators.farmName('OPG Horvat 2'), isNull);
    });

    test('odbija naziv dulji od 100 znakova', () {
      final maxLength = 'x' * ProfileValidators.maxFarmNameLength;
      expect(ProfileValidators.farmName(maxLength), isNull);
      expect(
        ProfileValidators.farmName('${maxLength}x'),
        'Naziv gospodarstva može imati najviše 100 znakova.',
      );
    });
  });
}
