# Dnevnik uporabe AI-ja za dvofaktorsku autentifikaciju

## 25. 11. 2026. · Planiranje

**Alat** — OpenAI Codex.

**Upit** — Razraditi 2FA za postojeći projekt, uključujući kriterije prihvatljivosti i uporabu AI-ja. Plan zatim podijeliti u tri logička commita koja se rade redom.

**Što je AI pregledao i predložio**

- Pregledao je obrazac prijave, ugovor `AuthService`, Firebaseovu implementaciju i postojeće widget testove. Utvrdio je da zaslon nakon uspješnog poziva servisa odmah otvara početni zaslon.
- U dokumentaciji i lokalnom SDK-u provjerio je da postojeća verzija `firebase_auth` 5.7.0 ima API za TOTP te da stvarna provjera ovisi o Identity Platformu. Predložio je razlikovati dovršenu prijavu od zahtjeva za drugim faktorom.
- Predložio je redoslijed od tri samostalna koraka. Prvo prijava računom koji već ima drugi faktor, zatim aktivacija u Postavkama te na kraju potvrda drugog faktora kod promjene lozinke. Priče i kriteriji zapisani su u [planu radionice](docs/xp-radionica.md).

**Odluke studenta** — Student je odabrao Android i TOTP iz autentifikatorske aplikacije te potvrdio da je za demonstraciju dostupan testni Firebase projekt. Zatražio je rad po jednom commitu i TDD. Za prvi korak ograničio je zadatak na prijavu.

## 25. 11. 2026. · TDD za prvu priču

**Upit** — „implementiraj samo korak 1 pa stani, pazi da je TDD“.

Codex je napisao tri widget testa. Nakon dodavanja minimalnog ugovora i lažnog servisa, testovi su se izvršili prije izmjene zaslona i sva tri pala. Prvi je pronašao otvoreni početni zaslon čim je servis vratio zahtjev za drugim faktorom. Ostala dva pala su jer obrazac za unos koda još nije postojao.

| Scenarij | Što je test potvrdio nakon implementacije |
| --- | --- |
| Ispravan kod | Kod `012345` zadržava početnu nulu. Prekratak kod se odbija, a početni zaslon ostaje zatvoren dok je provjera u tijeku. |
| Pogrešan kod | Korisnik vidi poruku o pogrešci i ostaje neprijavljen. Može ponovno unijeti kod. |
| Odustajanje i istek | Odustajanje vraća na unos lozinke. Istek vraća na prijavu uz poruku da treba ponovno započeti postupak. |

## 25. 11. 2026. · Implementacija i provjera prvog commita

Codex je implementirao novu granu toka u servisu i sučelju. Kad Firebase zatraži TOTP, servis vraća zahtjev za potvrdu koji zadržava Firebaseov resolver u memoriji. Zaslon traži šest znamenki i otvara početni zaslon nakon uspješne Firebase potvrde. Postojeći testovi i dalje pokrivaju običnu prijavu.

Tri ciljana testa prošla su nakon implementacije. Cijeli lokalni paket završio je s 217 prolaznih Flutter testova, a `flutter analyze --no-pub` bez nalaza. Widget testovi koriste lažni autentifikacijski servis. Stvarna prijava na Androidu s računom koji ima registriran TOTP ostaje za provjeru na testnom projektu. Promjene prve priče spremljene su u commit `fbeb6b6`.

## 25. 11. 2026. · Početak druge priče

**Alat i upit** — OpenAI Codex. Uputa je bila započeti drugi commit, koji obuhvaća uključivanje TOTP-a u Postavkama.

**Doprinos i provjera** — Codex je dodao i pokrenuo jedan widget test za prvi kriterij prihvatljivosti. Test očekuje da račun s nepotvrđenom e-adresom dobije mogućnost slanja potvrde prije nego što može vidjeti ključ za postavljanje. Test se izvršio i pao jer na zaslonu još nema gumba „Uključi 2FA“. Implementacija aktivacije tek slijedi.

## Razina uporabe AI-ja

U planiranju je AI pomagao pregledom koda, dokumentacije i testnih scenarija, a student je postavio opseg i odabrao pristup. Pri implementaciji prve priče Codex je na izričit zahtjev napisao testove i implementirao cijeli tok prijave s drugim faktorom. Taj dio evidentiran je kao razina 4 za jednu priču, koju pravila radionice dopuštaju.

Za sljedeće priče predviđena je razina 3. Student zadaje kriterije, traži pomoć oko pojedinačnog isječka ili testnog scenarija, sam integrira rješenje i bilježi što je iz AI prijedloga prihvatio, izmijenio ili odbacio te kako je to provjerio. [Smjernice FOI-ja](https://dokumenti.foi.hr/document/download/362)

## 25. 11. 2026. · Promjena lozinke uz TOTP

**Alat i upit** — OpenAI Codex. Uputa „oke napravi commit 3“ odnosila se na cijelu priču o promjeni lozinke uz TOTP.

**Doprinos** — Codex je dodao i pokrenuo dva widget testa prije uvođenja TOTP dijaloga, zatim implementirao dijalog i Firebaseovu ponovnu autentifikaciju. Firebaseova potvrda mora vrijediti za isti račun prije spremanja nove lozinke. Budući da je Codex napisao testove i implementirao cijelu priču, doprinos odgovara razini 4 i premašuje planiranu razinu 3. Radionica predviđa razinu 4 za jednu priču.

**Provjera** — Oba nova testa prvo su pala jer dijalog za potvrdu još nije postojao. Nakon implementacije prolaze, zajedno s postojećim testovima prijave i promjene lozinke. Testovi provjeravaju da se lozinka mijenja tek nakon ispravnog koda i da se nakon pogrešnog koda ili odustajanja promjena ne izvršava. Statička analiza nema nalaza. Stvarna promjena lozinke s TOTP računom na Androidu još čeka provjeru.

## 25. 11. 2026. · Dodatna provjera

**Alat i upit** — OpenAI Codex. Student je zatražio pregled dovršenih 2FA tokova, mali refaktor i dodatne testove te odgodio commit.

**Doprinos i provjera** — Codex je u prijavi ponovno iskoristio postojeći prevoditelj Firebaseovih pogrešaka i dodao dva widget testa za promjenu lozinke. Prvi provjerava da istek potvrde zahtijeva novi postupak, a drugi da je tijekom provjere blokirana ponovna potvrda i izlazak iz dijaloga. Prošao je 221 lokalni test uz izostavljen očekivano crveni test aktivacije iz druge priče. Statička analiza prošla je bez nalaza. Provjera s pravim Firebase računom na Androidu još je otvorena.

## 25. 11. 2026. · Dovršetak aktivacije u Postavkama

**Alat i upit** — OpenAI Codex. Student je zatražio dovršetak cijelog 2FA toka i izmjenu zadnjeg lokalnog commita nakon provjere.

**Doprinos** — Codex je proširio widget testove za potvrdu e-adrese, aktivaciju tek nakon valjanog koda i odustajanje. Zatim je implementirao Firebaseov postupak registracije TOTP faktora uz potvrđenu e-adresu, ponovni unos lozinke i prvi kod iz autentifikatora. Test odjave sada se pomiče do gumba na duljem zaslonu. Doprinos obuhvaća cijelu priču i prema opsegu odgovara razini 4.

**Provjera** — Tri testa aktivacije pala su prije implementacije jer u Postavkama nije postojao ulaz za aktivaciju. Nakon implementacije prošla su sva 224 lokalna Flutter testa bez izostavljanja, a statička analiza završila je bez nalaza. Za stvarnu provjeru prijave, aktivacije i promjene lozinke na testnom Firebase projektu zabilježen je [postupak za Android](docs/xp-radionica.md#provjera-2fa-na-androidu).
