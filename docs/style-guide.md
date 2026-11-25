# Ringfall — Dokumentacja stylu graficznego i dźwiękowego (M0)

## 1. Założenia techniczne i skala (Godot 4)

- **Perspektywa:** Klasyczny belt-scroller 2.5D (ruch w osi X oraz w głąb pasa terenu Y, skok symulowany w pionie z rzutowanym cieniem na ziemi).
- **Bazowa rozdzielczość viewportu:** `480×270` (proporcje 16:9).
- **Docelowe okna PC:** `1280×720` lub `1920×1080` (`480×270` skaluje się dokładnie `×4` do `1920×1080`).
- **Filtrowanie tekstur:** `Nearest` (brak rozmycia pikseli).
- **Sortowanie głębi:** `Y-Sort` na warstwie aktorów i obiektów areny, z punktem zakotwiczenia (*pivot*) przy stopach postaci.

## 2. Styl graficzny (Pixel Art — Mroczne Epickie Fantasy)

- **Inspiracje:** *Blasphemous* (ciężar, gotycko-mroczny klimat, czytelne sylwetki, surowa architektura) oraz *Hyper Light Drifter* (wyraziste akcenty świetlne i kolorystyczne przy atakach i efektach).
- **Proponowana skala zasobów:**
  - Kafelki terenu / tła: `16×16` lub `32×32` px.
  - Bohater i standardowi przeciwnicy: siatka bazowa `32×32` do `48×48` px (wysokość sylwetki ok. `28–36` px).
  - Bossowie: `64×64` do `96×96` px, wyraźnie więksi i bardziej masywni od zwykłych wrogów.
- **Czytelność walki w 2.5D:**
  - Wyraźny, ciemny owalny cień pod stopami każdej postaci i wroga (kluczowy do oceny głębi i wysokości skoku).
  - Kontrast tła i postaci: tła stonowane (zgniłe zielenie, chłodne szarości, popiół, czerń), natomiast bohater, wrogowie, telegrafy ataków i błyski ciosów mają wyraźne kontury i mocniejsze akcenty kolorystyczne (np. zimna stal, żar ognia, złoto/fiolet Pierścienia).
- **Zasada dla M1 (Placeholdery):**
  - W pierwszym prototypie używamy prostych pixel-artowych brył/sylwetek z wyraźnym cieniem, kierunkiem patrzenia i kolorem sygnalizującym stan (`idle`, `attack` / telegraf, `hurt`, `dash`).

## 3. Palety barw (kierunek dla kolejnych etapów)

- **Wioska / Pogranicze:** przygaszona zieleń, zgaszony brąz, mglisty błękit zmierzchu.
- **Mroczny Las / Ruiny:** głęboka zieleń, ciemny fiolet cienia, chłodny kamień.
- **Podziemia:** bazaltowa szarość, wilgotny granat, słabe ciepłe akcenty pochodni.
- **Popielate Pustkowia i Góra Przeznaczenia:** czerń wulkaniczna, popielata szarość, żarząca się czerwień i pomarańcz lawy.
- **Pierścień i korupcja:** złoty blask przechodzący przy wysokiej korupcji w niepokojącą czerwień/fiolet.

## 4. Styl dźwiękowy i muzyczny

- **Kierunek muzyczny:** mroczne fantasy ambientowo-orkiestrowe — powolne, ciężkie smyczki, niskie drony, bębny i chóry w kluczowych momentach oraz podczas walk z bossami.
- **Efekty dźwiękowe (SFX):**
  - Wyraźne, „mięsiste” dźwięki walki wręcz: świst ostrza, ciężkie uderzenie (*impact*), metaliczny zgrzyt, krótki dźwięk uniku (`dash`) i wyraźny sygnał ostrzegawczy przed silnym atakiem bossa.
  - Dźwięki otoczenia budujące nastrój: wiatr, trzask ognia, kroki zależne od podłoża (trawa, kamień, popiół).
  - Audio Pierścienia: subtelny szept/rezonans przy aktywacji mocy, narastający wraz z poziomem korupcji.
- **Zasada dla M1/M2:** M1 skupia się na mechanice (opcjonalnie bez audio lub z pojedynczymi dźwiękami testowymi); tymczasowe SFX i muzykę dodajemy w M2.
