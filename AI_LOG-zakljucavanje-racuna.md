# AI_LOG: zaključavanje računa (`xp-radionica/zakljucavanje-racuna`)

AI agent: Claude Code
Razina primjene AI-a (po Smjernicama): **4**

Prema pravilima radionice ovo je jedina priča tima na razini 4: agentu su dani
kriteriji prihvatljivosti i zatraženi su prvo testovi, a tek onda kod. Rješenje je
pregledano, uklopljeno u postojeću arhitekturu i tim ga zna objasniti.

## Ključni upiti i odluke

| # | Upit / situacija | Prijedlog AI-a | Odluka tima |
|---|---|---|---|
| 1 | Pregled PDF-a radionice i teme 13 | Sažetak pravila, upozorenje da Google prijava i 2FA traže podešavanje u Firebase konzoli | Tema podijeljena na troje; moja priča je zaključavanje računa |
| 2 | Kako izvesti zaključavanje | Dekorator `LockoutAuthService` oko postojećeg `AuthService`, brojač iza sučelja `LoginAttemptStore` | Prihvaćeno: ne dira login zaslon ni Firebase servis, pa nema konflikata s kolegama |
| 3 | Gdje čuvati brojač | U memoriji, bez nove ovisnosti u `pubspec.yaml` | Prihvaćeno zbog vremena i izbjegavanja konflikta; trajna pohrana ostaje kao mogućnost |
| 4 | TDD | Prvo unit testovi (7), pokrenuti crveni, zatim kod | Prihvaćeno, testovi prolaze |
| 5 | Test prihvatljivosti | Widget test u zasebnoj datoteci, prema kriterijima iz priče | Prihvaćeno: zasebna datoteka da se ne dira `login_screen_test.dart` |
| 6 | Kod greške `account-locked` | Premješten u `domain`, jer zaslon ne smije uvoziti `data` sloj | Prihvaćeno |
| 7 | Imena datoteka | `AI_LOG` i dokumentacija nazvani po grani | Odluka tima, da se ne miješa s kolegama |

## Gdje je AI pomogao

- Brzo je predložio dizajn koji se uklapa u postojeću arhitekturu (`AuthService`, `FakeAuthService`).
- Napisao je testove za rubne slučajeve: mrežne greške, velika i mala slova u e-mailu, istek zaključavanja.

## Gdje je AI griješio ili trebao korekciju

- U prvoj verziji zaslon prijave uvozio je `data` sloj zbog koda greške; ispravljeno premještanjem konstante u `domain`.
- AI je predložio zajedničke datoteke `docs/xp-radionica.md` i `AI_LOG.md`; tim je odlučio da se nazovu po grani, da se ne miješaju s radom kolega.
- `flutter pub get` je izmijenio generirane datoteke (`linux/`, `macos/`); trebalo ih je svjesno izostaviti iz commitova.
