/// Pravila za provjeru unosa na zaslonima autentikacije.
///
/// Svaka metoda vraća poruku greške na hrvatskom ili `null` ako je unos
/// ispravan, pa se može izravno predati kao `validator` polju forme.
class AuthValidators {
  AuthValidators._();

  /// Najmanja duljina lozinke. Firebase Authentication odbija kraće lozinke.
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Molimo unesite e-mail adresu.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Unesite ispravnu e-mail adresu.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Molimo unesite lozinku.';
    }
    if (value.length < minPasswordLength) {
      return 'Lozinka mora imati najmanje $minPasswordLength znakova.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Molimo potvrdite lozinku.';
    }
    if (value != password) {
      return 'Lozinke se ne podudaraju.';
    }
    return null;
  }
}
