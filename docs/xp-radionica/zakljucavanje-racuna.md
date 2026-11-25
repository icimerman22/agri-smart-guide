# XPAI radionica: Zaključavanje računa nakon 5 neuspjelih prijava

Tema iz kataloga: **13. Sigurnija prijava**
Grana: `xp-radionica/zakljucavanje-racuna` (iz `xp-radionica/dev`)

## Korisnička priča

> Kao korisnik želim da se moj račun privremeno zaključa nakon 5 neuspjelih
> prijava, kako netko ne bi mogao pogađati moju lozinku.

**Procjena:** 3 boda

## Kriteriji prihvatljivosti

1. **Zadano:** 4 neuspjele prijave za isti e-mail.
   **Kada:** peti put unesem pogrešnu lozinku.
   **Tada:** vidim poruku „Račun je privremeno zaključan nakon 5 neuspjelih
   pokušaja. Pokušajte ponovno za 15 minuta.“
2. **Zadano:** račun je zaključan.
   **Kada:** unesem točnu lozinku.
   **Tada:** prijava je odbijena, Firebase se ne poziva i ostajem na zaslonu
   prijave.
3. **Zadano:** prošlo je 15 minuta od zaključavanja ili je prijava uspjela.
   **Tada:** brojač neuspjelih pokušaja se resetira.

Mrežne greške (`network-request-failed`) ne broje se kao neuspjeli pokušaj.

## Testovi

| Vrsta | Datoteka |
|---|---|
| Test prihvatljivosti (widget) | `test/features/auth/presentation/login_lockout_acceptance_test.dart` |
| Unit testovi logike | `test/features/auth/data/lockout_auth_service_test.dart` |

Oba su napisana prije koda (crveno → zeleno).

## Dizajn

- `LockoutAuthService` je **dekorator** oko postojećeg `AuthService`: implementira
  isto sučelje i omota `FirebaseAuthService`. Login zaslon i Firebase servis
  ostaju netaknuti; povezivanje je jedan redak u `lib/main.dart`.
- Brojač je iza sučelja `LoginAttemptStore` (trenutno `InMemoryLoginAttemptStore`).
  Trajna pohrana (npr. `shared_preferences`) može se dodati kao nova klasa bez
  izmjene postojećeg koda.
- Sat se ubacuje izvana (`now`), pa testovi mogu „premotati“ vrijeme.

## Ograničenja

- Zaštita je na strani klijenta: brojač se resetira ponovnim pokretanjem
  aplikacije i može se zaobići. Pravo zaključavanje bilo bi na poslužitelju
  (npr. Cloud Function).
- Firebase Authentication već ima ugrađenu zaštitu `too-many-requests`.

## Commitovi

1. Logika zaključavanja i unit testovi.
2. Povezivanje s aplikacijom, poruka na zaslonu prijave, test prihvatljivosti i
   dokumentacija.
