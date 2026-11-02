/// Prevodi kodove grešaka Firebase Authenticationa u poruke za korisnika.
class AuthErrorMessages {
  AuthErrorMessages._();

  /// Poruka za neuspjelu registraciju prema `FirebaseAuthException.code`.
  static String registration(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Račun s ovom e-mail adresom već postoji.';
      case 'invalid-email':
        return 'Format e-mail adrese nije valjan.';
      case 'weak-password':
        return 'Lozinka je preslaba. Odaberite jaču lozinku.';
      case 'network-request-failed':
        return 'Nema internetske veze. Provjerite vezu i pokušajte ponovno.';
      case 'too-many-requests':
        return 'Previše pokušaja. Pričekajte malo pa pokušajte ponovno.';
      default:
        return 'Registracija nije uspjela. Pokušajte ponovno.';
    }
  }
}
