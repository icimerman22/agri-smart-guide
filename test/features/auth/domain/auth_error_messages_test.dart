import 'package:agri_smart_guide/features/auth/domain/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthErrorMessages.registration', () {
    test('javlja da račun s e-mail adresom već postoji', () {
      expect(
        AuthErrorMessages.registration('email-already-in-use'),
        'Račun s ovom e-mail adresom već postoji.',
      );
    });

    test('ima poruke za ostale poznate greške', () {
      expect(
        AuthErrorMessages.registration('invalid-email'),
        'Format e-mail adrese nije valjan.',
      );
      expect(
        AuthErrorMessages.registration('weak-password'),
        'Lozinka je preslaba. Odaberite jaču lozinku.',
      );
      expect(
        AuthErrorMessages.registration('network-request-failed'),
        'Nema internetske veze. Provjerite vezu i pokušajte ponovno.',
      );
      expect(
        AuthErrorMessages.registration('too-many-requests'),
        'Previše pokušaja. Pričekajte malo pa pokušajte ponovno.',
      );
    });

    test('za nepoznat kod vraća općenitu poruku', () {
      expect(
        AuthErrorMessages.registration('nesto-neocekivano'),
        'Registracija nije uspjela. Pokušajte ponovno.',
      );
    });
  });
}
