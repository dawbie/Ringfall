# Ringfall

**2D gra inspirowana klimatem epickiego fantasy i podróży przez niebezpieczny świat.**

> Ten plik to główna lista checkpointów projektu. Zaznaczaj `[x]` po ukończeniu zadania, a przy większych zmianach aktualizuj status i zakres kamieni milowych.

## Status projektu

- **Silnik:** Godot 4 (GDScript, projekt w `game/`)
- **Typ gry:** 2.5D belt-scroller, przygodowa gra akcji z elementami RPG (tryb solo na start)
- **Platforma docelowa:** PC (viewport bazowy `480×270`, okno `1280×720` / `1920×1080`, klawiatura + mysz / pad)
- **Etap:** M1 — Grywalny prototyp (M0 ukończony)
- **Najbliższy cel:** przygotować grywalny prototyp poruszania się i walki (M1)

## Wizja gry

Gracz przemierza niebezpieczną krainę, rozwija bohatera i podejmuje decyzje wpływające na przebieg wyprawy. Gra ma łączyć eksplorację, starcia z przeciwnikami, odkrywanie historii świata oraz wyrazistą, pixel-artową oprawę 2.5D w klimacie mrocznego fantasy.

### Ustalenia kierunkowe

- **Perspektywa i ruch:** klasyczny belt-scroller 2.5D (ruch w poziomie, w głąb pasa terenu oraz skok).
- **Tryb gry:** dla jednego gracza (solo na start; ewentualny co-op — **do decyzji** później).
- **Bohater i cel wyprawy:** Frodo niosący Pierścień do Góry Przeznaczenia przez 5 etapów zakończonych trudniejszymi bossami *(na potrzeby prywatnego prototypu; ewentualna zmiana nazw przed publikacją — odłożona na później)*.
- **Rola Pierścienia:** przedmiot fabularny oraz moc wysokiego ryzyka w walce — używanie zwiększa **ukrytą korupcję**, która wpływa na zakończenie (system ukryty przed graczem).
- **Oprawa graficzna i audio:** mroczny pixel art (inspiracje: *Blasphemous*, *Hyper Light Drifter*, bazowe `480×270`, placeholdery w M1) oraz mroczne fantasy ambientowo-orkiestrowe z wyraźnymi efektami ciosów.
- **Model walki:** dynamiczna walka wręcz z unikiem (`dash`/`roll`) i wyraźnym wyczuciem trafień.
- **Dokumentacja M0:** [Zarys fabuły](docs/story.md) · [Styl graficzny i dźwiękowy](docs/style-guide.md)

### Główna pętla rozgrywki

1. Przygotuj się do wyprawy w bezpiecznym miejscu.
2. Eksploruj lokację, szukaj ścieżek, przedmiotów i sekretów.
3. Walcz lub omijaj zagrożenia.
4. Zbieraj zasoby i rozwijaj postać.
5. Ukończ cel lokacji, poznaj fragment historii i odblokuj dalszą drogę.

## Kamienie milowe

### M0 — Plan i fundamenty

- [x] Ustalić główny gatunek i perspektywę — klasyczny belt-scroller 2.5D (tryb solo na start).
- [x] Opisać głównego bohatera, jego motywację i cel wyprawy — Frodo niosący Pierścień do Góry Przeznaczenia (na etap prototypu; ewentualne autorskie nazwy przed publikacją odłożone na później).
- [x] Przygotować krótki zarys fabuły oraz zakończenia — [docs/story.md](docs/story.md) (5 etapów z bossami + finał zależny od ukrytej korupcji).
- [x] Określić docelową platformę, rozdzielczość i wersję Godota — PC, Godot 4 (GDScript), bazowy viewport `480×270` skalowany do `1280×720` / `1920×1080`.
- [x] Założyć projekt Godot i ustalić strukturę katalogów (`game/` z podziałem na `scenes/`, `scripts/`, `assets/`, `ui/` oraz `.gitignore`).
- [x] Przygotować dokumentację stylu graficznego i dźwiękowego — [docs/style-guide.md](docs/style-guide.md).

### M1 — Grywalny prototyp

- [ ] Utworzyć projekt 2D w Godot 4 (GDScript) z ustawieniami renderowania pod pixel art (`Nearest`) i mapą wejść (klawiatura + mysz / pad).
- [ ] Zbudować testową arenę 2.5D z granicami pasa terenu, kolizjami i sortowaniem głębi (`Y-Sort`).
- [ ] Zaimplementować ruch bohatera w 2.5D (oś pozioma, głębia, skok z cieniem na ziemi) oraz kamerę (`Camera2D`).
- [ ] Dodać podstawowe animacje placeholderowe bohatera (`idle`, `run`, `jump`, `dash`, `attack`, `hurt`, `dead`).
- [ ] Dodać jednego przeciwnika testowego z prostym AI (wyrównywanie głębi, telegraf ataku, atak, otrzymywanie obrażeń).
- [ ] Zaimplementować podstawowy atak wręcz (z kontrolą głębi trafienia), unik (`dash`/`roll`), odrzut i czytelny feedback trafień.
- [ ] Dodać pasek zdrowia (HUD) oraz ekran porażki i zwycięstwa z możliwością szybkiego restartu.
- [ ] Przetestować prototyp i spisać problemy do poprawy.

**Gotowe, gdy:** można uruchomić grę, poruszać się po lokacji, walczyć z przeciwnikiem i zakończyć próbę porażką lub zwycięstwem.

### M2 — Główna mechanika i pionowy wycinek

- [ ] Wybrać i dopracować podstawowy model walki.
- [ ] Dodać uniki lub blokowanie (wybrać mechanikę pasującą do projektu).
- [ ] Dodać interakcje z obiektami i postaciami niezależnymi.
- [ ] Przygotować jedną małą, dopracowaną lokację z początkiem i końcem.
- [ ] Dodać cel zadania i prosty ekran jego ukończenia.
- [ ] Przygotować tymczasowe efekty dźwiękowe i muzykę.
- [ ] Przetestować wycinek z innymi osobami i zebrać uwagi.

**Gotowe, gdy:** krótki fragment gry pokazuje reprezentatywnie ruch, walkę, eksplorację, oprawę i cel rozgrywki.

### M3 — Systemy gry

- [ ] Dodać ekwipunek i przedmioty użytkowe.
- [ ] Dodać rozwój postaci (np. umiejętności lub statystyki).
- [ ] Dodać dialogi i podstawowy system zadań.
- [ ] Dodać punkty kontrolne i zapis/odczyt stanu gry.
- [ ] Dodać menu główne, pauzę i ustawienia.
- [ ] Dodać obsługę klawiatury oraz — jeśli planowana — kontrolera.
- [ ] Zdecydować, które systemy są konieczne dla pierwszej wersji gry.

### M4 — Zawartość gry

- [ ] Rozplanować mapę, lokacje i kolejność ich odblokowywania.
- [ ] Napisać scenariusz, dialogi i opisy zadań.
- [ ] Przygotować finalne grafiki postaci, przeciwników i otoczenia.
- [ ] Dodać zestawy przeciwników i stopniowanie trudności.
- [ ] Dodać nagrody, sekrety i przedmioty fabularne.
- [ ] Przygotować muzykę, efekty dźwiękowe i ambient.
- [ ] Dodać zakończenie oraz napisy końcowe.

### M5 — Testy i dopracowanie

- [ ] Naprawić błędy blokujące ukończenie gry.
- [ ] Zbalansować zdrowie, obrażenia, zasoby i poziom trudności.
- [ ] Poprawić czytelność walki i informacji na ekranie.
- [ ] Sprawdzić zapisy gry i zachowanie po ponownym uruchomieniu.
- [ ] Przetestować różne rozdzielczości i proporcje ekranu.
- [ ] Dodać opcje głośności i podstawowe ustawienia dostępności.
- [ ] Przeprowadzić testy gry od początku do końca.
- [ ] Przygotować listę znanych ograniczeń i ostatnie poprawki.

### M6 — Wydanie

- [ ] Przygotować ikonę, zrzuty ekranu i opis gry.
- [ ] Zbudować i sprawdzić wersję na platformę docelową.
- [ ] Zweryfikować, czy wszystkie użyte zasoby mają odpowiednią licencję.
- [ ] Przygotować wersję wydaniową i kopię zapasową projektu.
- [ ] Opublikować grę oraz zanotować znane problemy.

## Backlog — pomysły do rozważenia

- [ ] Alternatywne zakończenia zależne od decyzji gracza.
- [ ] Dodatkowe wyzwania lub opcjonalne lokacje.
- [ ] Tryb nowej gry plus.
- [ ] Dodatkowe poziomy trudności.
- [ ] Tłumaczenia na inne języki.

## Zasady pracy

- Najpierw ukończ mały, grywalny fragment — dopiero potem rozbudowuj zakres.
- Każde zadanie powinno być na tyle małe, by dało się je przetestować osobno.
- Oznaczaj elementy nieustalone jako **do decyzji**, zamiast zakładać, że są już częścią gry.
- Używaj oryginalnych postaci, nazw, fabuły i zasobów albo materiałów, do których masz prawa.
- Po każdym kamieniu milowym zrób działającą kopię projektu i zanotuj, co wymaga poprawy.

## Dziennik postępów

| Data | Kamień milowy | Postęp / uwagi |
|---|---|---|
| 2026-11-25 | M0 — Plan i fundamenty | Utworzono wstępny plan projektu. |
| 2026-11-25 | M0 — Plan i fundamenty | Ustalono belt-scroller 2.5D (solo), mroczny pixel art, walkę wręcz z unikiem, Godot 4 (GDScript), PC, placeholdery na M1 oraz bohatera i cel (Frodo / Pierścień / Góra Przeznaczenia); rozpisano plan M1. |
| 2026-11-25 | M0 — Plan i fundamenty | Zakończono M0: dodano zarys fabuły (`docs/story.md`), dokument stylu (`docs/style-guide.md`) oraz bazowy projekt Godot 4 w `game/`. |
