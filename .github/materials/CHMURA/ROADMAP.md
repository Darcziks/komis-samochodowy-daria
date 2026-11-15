# ROADMAP — Zaawansowane programowanie w chmurze

## 1. Po co jest ta mapa?

ROADMAP porządkuje pracę w przedmiocie **Zaawansowane programowanie w chmurze**.

Jej podstawą jest Karta przedmiotu.

ROADMAP nie zastępuje:

- Karty przedmiotu,
- instrukcji M1/M2,
- Notatek programisty,
- materiałów laboratoryjnych.

Pokazuje natomiast:

```text
GDZIE JESTEM?
CO TERAZ ROBIĘ?
DLACZEGO TO ROBIĘ?
JAKI JEST DOWÓD?
CO BĘDZIE DALEJ?
```

Model pracy:

```text
KARTA PRZEDMIOTU
        ↓
ROADMAP
        ↓
KAMIEŃ MILOWY
        ↓
ZADANIE
        ↓
NOTATKI PROGRAMISTY
        ↓
DOWÓD
```

---

# 2. Jak pracujemy na tym przedmiocie?

Nie uczymy się kolejnych platform tylko po to, aby poznać ich panele.

Budujemy jedną ścieżkę:

```text
APLIKACJA
        ↓
DANE
        ↓
USŁUGI CHMUROWE
        ↓
WDROŻENIE
        ↓
DIAGNOSTYKA
        ↓
DRUGIE ŚRODOWISKO
        ↓
PORÓWNANIE
        ↓
AUTOMATYZACJA
        ↓
BEZPIECZEŃSTWO I MONITORING
```

W bieżącej realizacji korzystamy z:

```text
Neon
→ dane
→ Object Storage
→ Neon CLI

Vercel
→ pierwsze wdrożenie

Cloudflare
→ drugie środowisko

Wrangler
→ CLI Cloudflare
```

---

# 3. Główne obszary przedmiotu

Zgodnie z Kartą przedmiotu rozwijamy przede wszystkim:

## CH1 — Usługi chmurowe i architektura

Student poznaje:

```text
usługę bazodanową
Object Storage
środowisko wykonawcze
konfigurację
zależności między usługami
```

Powiązane efekty:

```text
W01
U01
U04
```

---

## CH2 — Serverless i środowisko wykonawcze

Student rozwija rozumienie:

```text
aplikacja
→ funkcja / backend
→ środowisko chmurowe
→ automatyczne uruchomienie
```

Powiązane efekty:

```text
W02
U01
U05
```

---

## CH3 — Architektura usług

Student przechodzi od pojedynczej aplikacji do rozumienia:

```text
odpowiedzialność
→ usługa
→ komunikacja
→ zależności
```

Powiązane efekty:

```text
W02
U05
```

---

## CH4 — Automatyzacja i CI/CD

Student rozwija:

```text
Git
→ commit
→ test
→ deployment
→ weryfikacja
```

Powiązane efekty:

```text
W05
U03
U05
```

---

## CH5 — Bezpieczeństwo, monitoring i audyt

Student pracuje z:

```text
sekretami
konfiguracją
logami
monitoringiem
testami
audytem
```

Powiązane efekty:

```text
W03
U03
U04
```

---

# 4. M1 — fundament aplikacji korzystającej z usługi chmurowej

M1 jest wspólnym materiałem dla obu grup.

W CHMURA patrzymy jednak na M1 z perspektywy usług chmurowych.

Model:

```text
Node.js
→ konfiguracja
→ Neon PostgreSQL
```

Student powinien rozumieć:

```text
aplikacja
≠
baza danych

kod
≠
konfiguracja

lokalne uruchomienie
≠
usługa chmurowa
```

## Cel

Zrozumieć, że aplikacja lokalna może korzystać z zasobu działającego poza komputerem Studenta.

## Dowód

Student potrafi wykazać:

```text
aplikacja działa
+
połączenie z Neon działa
+
dane są odczytywane
+
sekrety nie znajdują się w repozytorium
```

---

# 5. M2 — integracja usług chmurowych

M2 również jest wspólnym materiałem.

W CHMURA jego głównym znaczeniem jest pokazanie, że aplikacja może korzystać z kilku różnych usług.

Model:

```text
                ┌→ PostgreSQL
Node.js ────────┤
                └→ Object Storage
```

Student powinien rozumieć:

```text
PostgreSQL
→ dane strukturalne

Object Storage
→ obiekty / pliki

backend
→ integruje oba zasoby
```

---

# 6. M2.1 — referencja pomiędzy usługami

Pracujemy z:

```text
image_object_key
```

Model:

```text
rekord PostgreSQL
        ↓
image_object_key
        ↓
Object Storage
```

Cel:

zrozumieć, że jeden zasób może przechowywać referencję do zasobu znajdującego się w innej usłudze.

---

# 7. M2.2 — dane a Object Storage

Student rozróżnia:

```text
dane strukturalne
≠
plik
≠
URL
≠
object key
```

Model:

```text
PostgreSQL
→ przechowuje dane

Object Storage
→ przechowuje obiekt

image_object_key
→ łączy oba światy
```

---

# 8. M2.3 — Neon CLI

## Aktualny etap

Neon CLI jest narzędziem wspierającym zarządzanie środowiskiem.

Nie jest osobnym celem przedmiotu.

Model:

```text
PowerShell
→ Neon CLI
→ Neon
→ projekt / branch / zasoby
```

Student poznaje:

```text
npx neonctl --help
npx neonctl login
npx neonctl me
npx neonctl projects list
npx neonctl projects get
npx neonctl link
npx neonctl branches
npx neonctl buckets
```

Najważniejszy model mentalny:

```text
GUI
→ obsługa ręczna

CLI
→ obsługa z terminala

skrypt
→ powtarzalność

pipeline
→ automatyzacja
```

Student powinien również rozumieć:

```text
Git branch
≠
Neon branch
```

## Dowód

Student potrafi:

```text
uruchomić Neon CLI
+
zalogować się
+
zidentyfikować projekt
+
rozpoznać branch
+
sprawdzić dostępne zasoby
```

---

# 9. M2.4 — Object Storage

Student tworzy rzeczywisty zasób Storage.

Model:

```text
projekt
→ branch
→ bucket
→ object
```

Docelowo:

```text
car-images
└── polonez.jpg
```

Student powinien rozumieć:

```text
bucket
object
object key
endpoint
credentials
```

## Dowód infrastruktury

```text
bucket istnieje
+
object istnieje
```

To jeszcze nie oznacza, że aplikacja potrafi z niego korzystać.

---

# 10. M2.5 — aplikacja ↔ Object Storage

Model:

```text
Node.js
→ konfiguracja
→ S3Client
→ Object Storage
```

Student wykorzystuje:

```text
@aws-sdk/client-s3
@aws-sdk/s3-request-presigner
dotenv
```

Plik diagnostyczny:

```text
scripts/check-storage.mjs
```

Przykładowy dowód:

```text
STORAGE_CONNECTION=PASS
BUCKET=car-images
OBJECT=polonez.jpg
```

Najważniejsze rozróżnienie:

```text
zasób istnieje
≠
aplikacja ma do niego dostęp
```

---

# 11. M2.6 — integracja PostgreSQL ↔ Object Storage

Model:

```text
PostgreSQL
cars.image_object_key
        │
        ▼
Object Storage
car-images/polonez.jpg
```

Docelowy warunek:

```text
DB key
=
Storage object key
```

## Dowód

Student potrafi wykazać:

```text
rekord posiada image_object_key
+
wskazany obiekt istnieje
+
aplikacja potrafi go sprawdzić
```

---

# 12. M2.7 — REST API

Model:

```text
klient
→ REST API
→ Node.js
→ PostgreSQL
→ Object Storage
```

Przykładowe endpointy:

```text
GET /health
GET /api/cars
```

Student powinien rozumieć:

```text
API
→ udostępnia dane

klient
→ nie musi znać szczegółów bazy i Storage
```

## Dowód

API działa lokalnie i korzysta z rzeczywistych usług.

---

# 13. M3 — pierwsze wdrożenie: Vercel

Po ustabilizowaniu aplikacji lokalnej przechodzimy do pierwszego wdrożenia.

Model:

```text
GitHub
→ Vercel
→ aplikacja / API
→ Neon
```

Student pracuje z:

```text
deploymentem
zmiennymi środowiskowymi
logami
publicznym endpointem
```

## Dowód

Student potrafi wykazać:

```text
aplikacja działa lokalnie
+
aplikacja działa na Vercel
+
publiczny endpoint odpowiada
+
konfiguracja środowiska jest poprawna
+
sekrety nie znajdują się w repozytorium
```

---

# 14. Po M3 — analiza wyniku

Nie przechodzimy automatycznie do kolejnej platformy.

Najpierw analizujemy wynik pracy z Vercel.

Pytania:

```text
Czy deployment zakończył się poprawnie?

Czy aplikacja odpowiada?

Czy baza jest dostępna?

Czy Object Storage jest dostępny?

Czy konfiguracja jest poprawna?

Czy występują błędy w logach?
```

Model diagnostyczny:

```text
kod
vs
konfiguracja
vs
deployment
vs
usługa zewnętrzna
```

---

# 15. M4 — drugie środowisko: Cloudflare

Cloudflare pojawia się dopiero po uzyskaniu wyniku z Vercel.

Cel:

```text
nie:
poznać kolejny panel

ale:
porównać dwa środowiska
```

Model:

```text
ta sama aplikacja
        │
        ├→ Vercel
        │
        └→ Cloudflare
```

Student porównuje:

```text
deployment
konfigurację
logi
środowisko wykonawcze
obsługę sekretów
diagnostykę
```

---

# 16. Wrangler

Wrangler jest narzędziem CLI środowiska Cloudflare.

Model:

```text
PowerShell
→ Wrangler
→ Cloudflare
```

Student wykorzystuje Wrangler do:

```text
uruchamiania
konfiguracji
deploymentu
diagnostyki
obsługi środowiska
```

Najważniejsze:

```text
Wrangler działa
≠
aplikacja działa poprawnie
```

Potrzebny jest rzeczywisty test endpointu.

---

# 17. Serverless — na podstawie rzeczywistego deploymentu

Dopiero po pracy z Vercel i Cloudflare przechodzimy do uporządkowania pojęcia serverless.

Student powinien rozumieć:

```text
aplikacja działa w środowisku chmurowym

ale

Student nie zarządza bezpośrednio serwerem
```

Model:

```text
request
→ środowisko wykonawcze
→ funkcja / backend
→ response
```

Nie uczymy się serverless wyłącznie z definicji.

Najpierw mamy doświadczenie, później budujemy model mentalny.

---

# 18. Architektura usług

Po integracji:

```text
PostgreSQL
+
Object Storage
+
API
+
hosting
```

Student analizuje odpowiedzialności usług.

Pytanie:

```text
Który element odpowiada za co?
```

Model:

```text
baza
→ dane

Object Storage
→ pliki

backend
→ logika

API
→ komunikacja

hosting
→ środowisko wykonawcze
```

To przygotowuje do bardziej zaawansowanego projektowania architektury.

---

# 19. Automatyzacja

Student przechodzi stopniowo:

```text
GUI
→ CLI
→ skrypt
→ pipeline
```

Najpierw:

```text
Neon CLI
```

później:

```text
Wrangler
```

następnie:

```text
automatyzacja deploymentu
```

Nie automatyzujemy procesu, którego Student wcześniej nie rozumie.

---

# 20. CI/CD

Model:

```text
kod
→ commit
→ test
→ deployment
→ weryfikacja
```

Student powinien rozumieć:

```text
pipeline zakończony
≠
aplikacja działa poprawnie
```

Po deploymentcie potrzebny jest dowód:

```text
endpoint odpowiada
+
usługi są dostępne
+
logi nie wskazują błędu krytycznego
```

---

# 21. Bezpieczeństwo przez cały projekt

Bezpieczeństwo nie jest ostatnim zadaniem.

Od początku stosujemy:

```text
sekrety
→ poza Git

konfiguracja
→ poza kodem

.env.local
→ lokalnie

zmienne środowiskowe
→ hosting

dostęp do usług
→ kontrolowany
```

Później rozwijamy:

```text
kontrolę dostępu
walidację
bezpieczeństwo API
analizę konfiguracji
```

---

# 22. Monitoring i logi

Student powinien rozróżniać:

```text
aplikacja działa
```

od:

```text
wiemy, co dzieje się z aplikacją
```

Logi pomagają odpowiedzieć:

```text
co się wydarzyło?
gdzie?
kiedy?
w której warstwie?
```

Pracujemy z logami rzeczywistych środowisk:

```text
Vercel
Cloudflare
```

---

# 23. Audyt

Audyt nie polega na samym wykonaniu testu.

Model:

```text
obserwacja
→ dowód
→ interpretacja
→ decyzja
```

Student powinien odróżniać:

```text
symptom
≠
przyczyna

błąd aplikacji
≠
błąd konfiguracji

błąd konfiguracji
≠
błąd usługi
```

---

# 24. Porównanie Vercel ↔ Cloudflare

Po wykonaniu pracy w obu środowiskach Student może porównać:

```text
Vercel
vs
Cloudflare
```

Nie na podstawie reklamy lub opisu produktu.

Na podstawie własnych doświadczeń:

```text
deployment
konfiguracja
CLI
logi
diagnostyka
obsługa sekretów
złożoność
```

Porównanie powinno wynikać z dowodów.

---

# 25. Rola Notatek programisty

Notatki programisty są wspólne dla obu grup.

Nie są osobnym kamieniem milowym.

Ich rola:

```text
DOŚWIADCZENIE
→ REFLEKSJA
→ MODEL MENTALNY
→ DIAGNOSTYKA
→ DOWÓD
→ TRANSFER
```

W CHMURA prowadzą szczególnie od:

```text
GUI
→ CLI
→ diagnostyki
→ automatyzacji
```

---

# 26. Kompetencje rozwijane przez cały przedmiot

## K01 — praca zespołowa

Rozwijamy poprzez:

```text
Git
Issue
Pull Request
wspólny kontrakt projektu
```

## K02 — krytyczna ocena narzędzi

Student powinien potrafić odpowiedzieć:

```text
Dlaczego użyłem tego rozwiązania?
Co ono rozwiązuje?
Jakie ma ograniczenia?
Jak zachowuje się w drugim środowisku?
```

## K03 — samokształcenie

Rozwijamy poprzez:

```text
--help
dokumentację
CLI
logi
diagnostykę
eksperyment
interpretację wyniku
```

---

# 27. Zasada przejścia

Nie przechodzimy dalej dlatego, że:

```text
"wykonałem instrukcję"
```

Student powinien potrafić odpowiedzieć:

```text
CO zrobiłem?
GDZIE?
DLACZEGO?
JAK TO SPRAWDZIŁEM?
JAKI MAM DOWÓD?
CO OZNACZA WYNIK?
```

Przy drugim środowisku dochodzi jeszcze:

```text
CO SIĘ ZMIENIŁO?
DLACZEGO?
```

---

# 28. Gdzie jesteśmy teraz?

```text
M1
✅ aplikacja ↔ Neon PostgreSQL

M2.1
✅ image_object_key

M2.2
✅ PostgreSQL ↔ Object Storage — model

M2.3
▶ TERAZ — Neon CLI

M2.4
○ Object Storage

M2.5
○ aplikacja ↔ Object Storage

M2.6
○ integracja usług

M2.7
○ REST API

M3
○ Vercel

po M3
○ analiza wyniku
○ diagnostyka

M4
○ Cloudflare
○ Wrangler
○ porównanie Vercel ↔ Cloudflare

dalej
○ automatyzacja
○ CI/CD
○ bezpieczeństwo
○ monitoring
○ audyt
```

---

# 29. Gdy nie wiesz, co robić

Wróć do tej kolejności:

```text
1. ROADMAP
→ gdzie jestem?

2. BIEŻĄCY KAMIEŃ MILOWY
→ co mam wykonać?

3. NOTATKI PROGRAMISTY
→ dlaczego to działa?

4. --help / dokumentacja
→ jak działa narzędzie?

5. DOWÓD
→ czy rzeczywiście działa?

6. PORÓWNANIE
→ co zmieniło się pomiędzy środowiskami?
```
