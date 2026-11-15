# ROADMAP TB — Technologie backendowe

## 1. Po co jest ta mapa?

1. Cel ROADMAP
ROADMAP porządkuje realizację przedmiotu Technologie backendowe i odpowiada na cztery pytania:
1. Czego Student ma się nauczyć zgodnie z Kartą przedmiotu?
2. W jakiej kolejności rozwijane są kompetencje?
3. Które kamienie milowe projektu realizują dane efekty?
4. Jakie dowody pokazują, że Student rzeczywiście wykonał pracę?
ROADMAP nie zastępuje:
- Karty przedmiotu,
- instrukcji M1/M2,
- Notatek programisty,
- materiałów laboratoryjnych.
Tworzy pomiędzy nimi strukturę.

## Jak wygląda cały przedmiot?

ROADMAP prowadzi przez pięć obszarów wynikających z Karty przedmiotu.

```text
TB1 — PODSTAWY BACKENDU
3 h
W01 / U01
│
└── M1
    Node.js
    → konfiguracja
    → PostgreSQL
    → Neon
        │
        ▼
TB2 — REST API
4 h
W02 / U02
        │
        ├── M2
        │   dane + Object Storage + API
        │
        └── dalsze rozwijanie endpointów
                │
                ▼
TB3 — BAZY DANYCH
4 h
W03 / U03
        │
        └── M1 + M2
            PostgreSQL
            → schemat
            → image_object_key
            → integracja danych
                │
                ▼
TB4 — AUTENTYKACJA I AUTORYZACJA
4 h
W04 / U04
        │
        └── kolejny etap
            logowanie
            → JWT
            → OAuth
            → kontrola dostępu
                │
                ▼
TB5 — BEZPIECZEŃSTWO BACKENDU
3 h
W05 / U05
        │
        └── walidacja
            → sekrety
            → SQL Injection
            → XSS
            → CSRF
                │
                ▼
        ZALICZENIE / OBRONA PROJEKTU
```
## M2.3 — Neon CLI

Neon CLI jest częścią realizacji M2.

Nie traktujemy go wyłącznie jako dodatkowego narzędzia, ponieważ Student wykorzystuje go do rzeczywistej pracy z projektem Neon i przygotowania kolejnych etapów.

### Cel

Przejść od pracy wyłącznie przez Neon Console do świadomej pracy z projektem z poziomu terminala.

Model:

```text
PowerShell
→ Neon CLI
→ projekt Neon
→ branch
→ zasoby
```

### Student poznaje

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

### Student powinien rozumieć

```text
GUI
→ pozwala zobaczyć środowisko

CLI
→ pozwala sprawdzać i zarządzać środowiskiem z terminala
```

oraz:

```text
Git branch
≠
Neon branch
```

### Dowód

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
powiązać lokalny projekt z Neon
+
sprawdzić dostępne zasoby
```

### Przejście dalej

Dopiero po tym etapie przechodzimy do:

```text
M2.4
→ Object Storage
→ bucket
→ object
```
### Jak czytać kamienie milowe?

Kamienie milowe nie zastępują bloków przedmiotu.

Pokazują, jak realizujemy je praktycznie:

```text
KARTA PRZEDMIOTU
→ określa czego masz się nauczyć

ROADMAP
→ pokazuje kolejność

M1 / M2 / kolejne kamienie milowe
→ prowadzą przez wykonanie

NOTATKI PROGRAMISTY
→ pomagają zrozumieć, diagnozować i przenieść wiedzę

DOWÓD
→ pokazuje, że rezultat rzeczywiście działa
```

---

## Kompetencje rozwijane przez cały przedmiot

Oprócz wiedzy i umiejętności technicznych rozwijamy także kompetencje zapisane w Karcie przedmiotu.

### K01 — praca zespołowa

W projekcie rozwijamy ją poprzez:

```text
Git
→ commit
→ branch
→ Issue
→ Pull Request
→ wspólny kontrakt projektu
```

### K02 — krytyczna ocena narzędzi

Student nie tylko korzysta z narzędzia.

Powinien umieć odpowiedzieć:

```text
Co to narzędzie rozwiązuje?
Dlaczego używamy go w tym miejscu?
Jakie ma ograniczenia?
Co mogłoby je zastąpić?
```

Dotyczy to m.in.:

```text
Neon
Neon CLI
Vercel
Cloudflare
Wrangler
Git
```

### K03 — samokształcenie

Rozwijamy je poprzez:

```text
--help
→ dokumentację
→ diagnostykę
→ eksperyment
→ interpretację wyniku
→ Notatki programisty
```

Student nie powinien być zależny wyłącznie od gotowej instrukcji.
```
