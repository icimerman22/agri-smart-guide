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

## Provjera 2FA na Androidu

Potreban je Android uređaj ili emulator i testni Firebase projekt s uključenim Identity Platformom, prijavom e-adresom i lozinkom te TOTP-om.

1. Prijaviti se testnim računom bez faktora. U Postavkama otvoriti **Uključi 2FA**. Ako e-adresa još nije potvrđena, poslati poruku, otvoriti poveznicu za potvrdu i u aplikaciji odabrati **Provjeri potvrdu**.
2. Unijeti trenutnu lozinku i dodati prikazani ključ kao vremenski kod u autentifikatoru. Pogrešan kod treba biti odbijen, a valjani kod treba prikazati status **2FA je uključen**. Za provjeru odustajanja koristiti drugi račun bez faktora.
3. Odjaviti se. U prijavi s uključenim 2FA provjeriti pogrešan kod, odustajanje i ispravan kod. Početni zaslon treba se otvoriti tek nakon uspješne potvrde.
4. U profilu pokrenuti promjenu lozinke. Pogrešan kod ili odustajanje trebaju ostaviti staru lozinku valjanom. Nakon ispravnog koda odjaviti se i provjeriti prijavu novom lozinkom uz TOTP.
