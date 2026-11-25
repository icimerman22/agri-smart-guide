# Dnevnik uporabe AI-ja za dvofaktorsku autentifikaciju

## 25. 11. 2026. · Planiranje

- **Alat i upit** — OpenAI Codex. Upit je bio isplanirati dvofaktorsku autentifikaciju za postojeću aplikaciju i rasporediti rad u tri logička commita.
- **Doprinos** — Codex je pregledao postojeći Flutter/Firebase tok prijave, testove i dokumentaciju te predložio TOTP, kriterije prihvatljivosti i redoslijed rada.
- **Odluka** — Student je odabrao Android, autentifikatorsku aplikaciju i zaseban Firebase projekt za demo. Zatražio je rad po jednom commitu, uz TDD.

## 25. 11. 2026. · Prijava drugim faktorom

- **Alat i upit** — OpenAI Codex. Uputa je bila implementirati samo prvi korak uz TDD i stati nakon prvog commita.
- **Doprinos** — Codex je napisao widget testove i implementirao cijeli prvi korak, uključujući promjenu ugovora servisa, Firebase potvrdu TOTP-a i obrazac za kod. Ovaj način rada prema opsegu generiranog koda odgovara razini 4 za ovu priču. Za sljedeće priče planirana je razina 3, uz pomoć za pojedinačne isječke i provjeru koju provodi student. [Smjernice FOI-ja](https://dokumenti.foi.hr/document/download/362)
- **Provjera** — Nakon dodavanja testnog sučelja, tri nova testa pala su prije implementacije. Zabilježili su prerani odlazak na početni zaslon i izostanak obrasca za kod. Nakon implementacije prolaze provjera ispravnog koda, odbijanje pogrešnog koda s ponovnim pokušajem, odustajanje i istek. Prošlo je svih 217 lokalnih Flutter testova, a statička analiza nije prijavila probleme. Stvarna prijava na testnom Firebase projektu još čeka provjeru na Androidu.
