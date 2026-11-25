# XP radionica · Dvofaktorska autentifikacija

Korisnici Agri Smart Guidea mogu dodatno zaštititi račun jednokratnim kodom iz autentifikatorske aplikacije. Cilj demonstracije je Android s testnim Firebase projektom.

| Iteracija | Korisnička priča | Bodovi | Kriteriji prihvatljivosti |
| --- | --- | ---: | --- |
| 1 | Kao korisnik s 2FA želim potvrditi prijavu kodom iz autentifikatora. | 3 | Račun bez 2FA ulazi nakon ispravne lozinke. Račun s 2FA ulazi tek nakon ispravnog koda. Pogrešan kod omogućuje ponovni pokušaj, a odustajanje ili istek vraćaju na prijavu. |
| 2 | Kao korisnik želim uključiti 2FA u Postavkama. | 3 | Korisnik može potvrditi e-adresu prije aktivacije. Nakon ponovnog unosa lozinke može unijeti ključ u autentifikator i potvrditi prvi kod. Pogrešan kod ili odustajanje ne aktiviraju 2FA. |
| 2 | Kao korisnik s 2FA želim promijeniti lozinku uz potvrdu identiteta. | 2 | Firebase prihvaća promjenu nakon potvrde trenutne lozinke i drugog faktora. Pogrešan kod ili odustajanje zadržavaju staru lozinku. |

## Brzina

- **Iteracija 1** — planirana 3 boda. Automatizirani kriteriji prolaze. Ostvarene bodove potvrditi nakon provjere na Androidu s testnim Firebase računom.
- **Iteracija 2** — planirano do 5 bodova. Uključivanje 2FA ima prednost. Opseg potvrditi nakon prve iteracije.

## Provjera prijave na Androidu

Za prvu iteraciju potreban je Android uređaj ili emulator i testni Firebase projekt s uključenim Identity Platformom i TOTP-om. Pripremiti račun s već registriranim TOTP faktorom i kodom koji je dostupan u autentifikatorskoj aplikaciji te zaseban račun bez faktora. Na testnoj konfiguraciji prvo provjeriti običnu prijavu, zatim s TOTP računom pokušati pogrešan kod, odustati i ponoviti prijavu ispravnim kodom. Pri svakom pokušaju provjeriti kada se otvara početni zaslon.
