import 'package:agri_smart_guide/features/auth/domain/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.email', () {
    test('vraća grešku za prazan unos', () {
      expect(AuthValidators.email(null), 'Molimo unesite e-mail adresu.');
      expect(AuthValidators.email(''), 'Molimo unesite e-mail adresu.');
      expect(AuthValidators.email('   '), 'Molimo unesite e-mail adresu.');
    });

    test('vraća grešku za neispravan format', () {
      for (final input in [
        'korisnik',
        'korisnik@',
        '@domena.hr',
        'korisnik@domena',
        'kori snik@domena.hr',
      ]) {
        expect(
          AuthValidators.email(input),
          'Unesite ispravnu e-mail adresu.',
          reason: input,
        );
      }
    });

    test('prihvaća ispravnu adresu, i s razmacima oko nje', () {
      expect(AuthValidators.email('korisnik@domena.hr'), isNull);
      expect(AuthValidators.email('  ime.prezime@foi.unizg.hr  '), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('vraća grešku za praznu lozinku', () {
      expect(AuthValidators.password(null), 'Molimo unesite lozinku.');
      expect(AuthValidators.password(''), 'Molimo unesite lozinku.');
    });

    test('vraća grešku za lozinku kraću od 6 znakova', () {
      expect(
        AuthValidators.password('12345'),
        'Lozinka mora imati najmanje 6 znakova.',
      );
    });

    test('prihvaća lozinku od točno 6 znakova i dulju', () {
      expect(AuthValidators.password('123456'), isNull);
      expect(AuthValidators.password('dugaLozinka123'), isNull);
    });
  });

  group('AuthValidators.confirmPassword', () {
    test('vraća grešku za praznu potvrdu', () {
      expect(
        AuthValidators.confirmPassword('', 'lozinka1'),
        'Molimo potvrdite lozinku.',
      );
    });

    test('vraća grešku kad se lozinke ne podudaraju', () {
      expect(
        AuthValidators.confirmPassword('lozinka2', 'lozinka1'),
        'Lozinke se ne podudaraju.',
      );
    });

    test('prihvaća jednake lozinke', () {
      expect(AuthValidators.confirmPassword('lozinka1', 'lozinka1'), isNull);
    });
  });
}
