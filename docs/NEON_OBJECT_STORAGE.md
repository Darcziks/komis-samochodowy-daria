# ATINS Komis — karta dostępu do Neon Object Storage
**Dla zespołów: Technologie Backendowe (TB) i CHMURA**
## 1. Do czego służy Object Storage?

W projekcie ATINS Komis baza **Neon PostgreSQL** przechowuje dane strukturalne, natomiast **Neon Object Storage** służy do przechowywania plików, np. zdjęć samochodów.

Object Storage udostępnia interfejs zgodny z **Amazon S3 API**. W aplikacji Node.js możemy więc korzystać z AWS SDK, wskazując endpoint i poświadczenia Neon.

Nie zapisujemy obrazów bezpośrednio w PostgreSQL.

Przykładowy podział:

```text
PostgreSQL
├── samochód
├── marka
├── model
├── cena
└── klucz / adres zdjęcia

Object Storage
└── cars/
    └── <carId>/
        └── <plik obrazu>
```

## 2. Wymagania

Przed rozpoczęciem sprawdź:

```powershell
node --version
npm --version
git status
```

Projekt powinien mieć również działające podstawowe kontrole:

```powershell
npm ci
npm run check:syntax
npm run typecheck
```

## 3. Neon CLI

Jeżeli korzystasz z Neon CLI, najpierw sprawdź jego dostępność:

```powershell
neon --version
```

Jeżeli projekt nie jest jeszcze powiązany z Neon, postępuj zgodnie z instrukcją prowadzącego dotyczącą konkretnego projektu lub brancha.

Nie twórz dodatkowego projektu Neon tylko dlatego, że nie widzisz Object Storage — najpierw sprawdź projekt wskazany dla laboratorium.

## 4. Konfiguracja Object Storage

Neon pozwala zadeklarować Object Storage jako usługę projektu.

Przykład utworzenia prywatnego bucketu w konfiguracji Neon:

```powershell
neon config add bucket car-images
```

Dla bucketu dostępnego publicznie do odczytu Neon obsługuje również:

```powershell
neon config add bucket assets --access public_read
```

W laboratorium domyślnie korzystaj z **bucketu prywatnego**, chyba że prowadzący wskaże inaczej.

Nie zmieniaj poziomu dostępu bucketu bez uzasadnienia.

## 5. Poświadczenia

Do połączenia aplikacji z Neon Object Storage potrzebne są następujące zmienne środowiskowe:

```text
AWS_ENDPOINT_URL_S3
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
S3_BUCKET
```

W projekcie laboratoryjnym mogą wyglądać schematycznie tak:

```text
AWS_ENDPOINT_URL_S3=<endpoint-z-Neon>
AWS_REGION=<region-z-Neon>
AWS_ACCESS_KEY_ID=<access-key>
AWS_SECRET_ACCESS_KEY=<secret-key>
S3_BUCKET=car-images
```

**Nie wpisuj rzeczywistych wartości do `.env.example`.**

Rzeczywiste wartości przechowuj wyłącznie lokalnie w pliku `.env` lub innym mechanizmie wskazanym w laboratorium.

## 6. Bezpieczeństwo

Nie publikuj:

- `AWS_ACCESS_KEY_ID`,
- `AWS_SECRET_ACCESS_KEY`,
- pełnego endpointu wraz z danymi dostępowymi,
- zawartości `.env`,
- tokenów Neon,
- screenshotów pokazujących sekrety.

Nie umieszczaj ich w:

- commitach,
- Pull Request,
- Issues,
- Discussions,
- README,
- raportach i screenshotach.

Przed commitem wykonaj:

```powershell
git status
git diff
git diff --cached
```

## 7. Sprawdzenie konfiguracji bez ujawniania wartości

Możesz sprawdzić tylko obecność wymaganych zmiennych:

```powershell
node --input-type=module -e "import 'dotenv/config'; for (const n of ['AWS_ENDPOINT_URL_S3','AWS_ACCESS_KEY_ID','AWS_SECRET_ACCESS_KEY','AWS_REGION','S3_BUCKET']) console.log(n+': '+(process.env[n]?.trim()?'USTAWIONA':'BRAK'))"
```

Oczekiwany rezultat:

```text
AWS_ENDPOINT_URL_S3: USTAWIONA
AWS_ACCESS_KEY_ID: USTAWIONA
AWS_SECRET_ACCESS_KEY: USTAWIONA
AWS_REGION: USTAWIONA
S3_BUCKET: USTAWIONA
```

Nie wypisuj wartości tych zmiennych.

## 8. AWS SDK

Jeżeli laboratorium wymaga pracy z Object Storage, zainstaluj:

```powershell
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
```

Przy bezpośrednim użyciu klienta S3 konfiguracja Neon wymaga:

```javascript
const s3 = new S3Client({
  endpoint: process.env.AWS_ENDPOINT_URL_S3,
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});
```

`forcePathStyle: true` jest istotnym elementem konfiguracji Neon Object Storage.

## 9. Minimalny test dostępu

Pierwszym testem nie powinien być od razu upload zdjęcia.

Najpierw sprawdź możliwość odczytu listy obiektów:

```javascript
import 'dotenv/config';
import {
  S3Client,
  ListObjectsV2Command
} from '@aws-sdk/client-s3';

const s3 = new S3Client({
  endpoint: process.env.AWS_ENDPOINT_URL_S3,
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

const result = await s3.send(
  new ListObjectsV2Command({
    Bucket: process.env.S3_BUCKET,
    MaxKeys: 10,
  })
);

console.log('Połączenie z Object Storage: OK');
console.log('Liczba obiektów:', result.Contents?.length ?? 0);
```

Udany `ListObjectsV2` potwierdza dostęp do listowania obiektów.

Nie potwierdza jeszcze prawa do zapisu lub usuwania.

## 10. Kolejność testowania

Pracuj stopniowo:

```text
konfiguracja zmiennych
        ↓
ListObjectsV2
        ↓
PutObject
        ↓
HeadObject
        ↓
DeleteObject
```

Nie przechodź od razu do pełnej funkcji uploadu, jeśli nie masz potwierdzonego podstawowego połączenia.

## 11. Bucket i branch Neon

Object Storage w Neon jest związany z branchami projektu.

Poświadczenia storage są również powiązane z branchem. Oznacza to, że dane dostępowe z jednego środowiska nie powinny być automatycznie przenoszone do innego projektu lub brancha.

Przed testem sprawdź, czy pracujesz na środowisku wskazanym dla laboratorium.

## 12. Typy dostępu do bucketu

Neon obsługuje m.in.:

```text
private
public_read
```

`private`:
- odczyt wymaga uwierzytelnienia,
- zapis wymaga uwierzytelnienia.

`public_read`:
- anonimowy odczyt jest dozwolony,
- zapis nadal wymaga uwierzytelnienia.

W projekcie laboratoryjnym nie ustawiaj `public_read` tylko dlatego, że ułatwia wyświetlanie zdjęć.

Najpierw oceń konsekwencje dostępu publicznego.

## 13. Co student powinien umieć wyjaśnić

Po wykonaniu ćwiczenia student powinien potrafić wskazać:

- dlaczego PostgreSQL i Object Storage pełnią różne role;
- czym jest bucket;
- czym różni się `S3_BUCKET` od `DATABASE_URL`;
- dlaczego klucz i sekret nie mogą znaleźć się w GitHub;
- dlaczego udany `ListObjectsV2` nie dowodzi jeszcze prawa do `PutObject`;
- gdzie aplikacja Node.js kończy się, a zaczyna usługa Neon;
- dlaczego problem z uploadem nie musi oznaczać awarii Neon.

## 14. Gdy coś nie działa

Najpierw sprawdź konfigurację:

```powershell
git status
npm run typecheck
```

Następnie obecność zmiennych środowiskowych — bez wypisywania ich wartości.

Rozdziel:

```text
symptom
→ warstwa, w której wystąpił
→ dowód
→ możliwa przyczyna
```

Przykład:

```text
„upload nie działa”
```

nie oznacza jeszcze:

```text
„Neon Object Storage ma awarię”
```

Problem może dotyczyć np. endpointu, regionu, poświadczeń, nazwy bucketu, uprawnień lub kodu klienta S3.

## 15. Źródła

Neon:
https://neon.com/docs

Projekt ATINS Komis:
https://github.com/ATINS-Labs/atins-komis-template

Informacje organizacyjne i aktualizacje:
https://github.com/ATINS-Labs/atins-komis-template/discussions
