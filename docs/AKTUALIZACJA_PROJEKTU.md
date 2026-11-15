# ATINS Komis — bezpieczna aktualizacja projektu studenckiego

**Dla zespołów: Technologie Backendowe (TB) i CHMURA**

## 1. Cel

Ta instrukcja opisuje sposób pobierania aktualizacji ze wspólnego szablonu ATINS Komis bez utraty własnych rozwiązań laboratoryjnych.

Repozytorium szablonowe:

https://github.com/ATINS-Labs/atins-komis-template

Ogłoszenia o aktualizacjach:

https://github.com/ATINS-Labs/atins-komis-template/discussions/2

**Ważne:** repozytoria utworzone przez *Use this template* nie aktualizują się automatycznie.

## 2. Przygotowanie i zabezpieczenie pracy

Otwórz terminal PowerShell w katalogu własnego projektu.

Sprawdź, z jakim repozytorium pracujesz:

```powershell
git remote -v
git branch --show-current
git status
```

Upewnij się, że `origin` wskazuje na **Twoje własne repozytorium**, a nie bezpośrednio na szablon organizacji.

Jeżeli masz niezapisane zmiany, zabezpiecz je przed dalszymi operacjami. Najlepiej zapisać zakończoną pracę na własnej gałęzi w commicie, po wcześniejszym sprawdzeniu, że nie zawiera haseł ani danych dostępowych.

Nie wykonuj `git reset --hard`, `git clean -fd` ani `git push --force`.

## 3. Dodanie repozytorium szablonowego

Sprawdź, czy remote `template` już istnieje:

```powershell
git remote get-url template
```

Jeśli nie istnieje, dodaj go:

```powershell
git remote add template https://github.com/ATINS-Labs/atins-komis-template.git
```

Jeśli remote już istnieje i wskazuje prawidłowy adres, nie dodawaj go ponownie.

## 4. Pobranie informacji o aktualizacjach

```powershell
git fetch template
```

To polecenie pobiera commity i gałęzie szablonu, ale nie zmienia plików projektu studenta.

Możesz sprawdzić ostatnie aktualizacje:

```powershell
git log template/main -5 --oneline
```

## 5. Porównanie zmian

Najpierw sprawdź, które pliki różnią się między Twoim projektem a szablonem:

```powershell
git diff --stat HEAD template/main
```

Następnie wyświetl listę zmienionych plików:

```powershell
git diff --name-status HEAD template/main
```

**Uwaga:** to porównanie pokazuje różnice między dwoma stanami repozytorium. Nie oznacza, że wszystkie widoczne zmiany należy zastosować do projektu studenta.

Jeżeli projekt został utworzony z szablonu, może nie posiadać z nim wspólnej historii Git.

## 6. Bezpieczne pobieranie aktualizacji

**Nie wykonuj automatycznie `git merge template/main`.**

GitHub Template Repository nie gwarantuje wspólnej historii commitów z repozytorium utworzonym przez *Use this template*.

Zalecany sposób aktualizacji:

1. Przeczytaj ogłoszenie prowadzącego dotyczące nowej wersji.
2. Ustal, które pliki zostały wskazane do aktualizacji.
3. Utwórz w swoim projekcie osobną gałąź aktualizacyjną.
4. Przenieś wyłącznie wskazane pliki lub zmiany.
5. Sprawdź różnice i uruchom testy projektu.
6. Po zatwierdzeniu aktualizacji włącz zmiany do własnej gałęzi roboczej.

Przykład utworzenia gałęzi:

```powershell
git switch -c update/materialy-lab
```

Przykład pobrania pojedynczego pliku ze szablonu:

```powershell
git restore --source=template/main -- docs/PROJECT_VERIFICATION.md
```

**Wykonuj takie polecenie tylko wtedy, gdy prowadzący wskaże dokładnie ten plik, a jego aktualna zawartość została wcześniej zabezpieczona.** Polecenie zastępuje zawartość wskazanego pliku w katalogu roboczym.

Nie kopiuj w ten sposób własnego pliku `.env` ani plików zawierających indywidualne rozwiązania.

## 7. Kontrola po aktualizacji

Sprawdź:

```powershell
git status
git diff
```

Uruchom testy, jeśli są dostępne w danej wersji projektu:

```powershell
npm ci
npm test
```

Jeśli aktualizacja dotyczy integracji z Neon, upewnij się, że korzystasz z właściwej bazy testowej. Nie uruchamiaj automatycznie skryptów SQL zmieniających dane.

## 8. Gdy pojawi się problem

Jeżeli wystąpi konflikt, błąd testów lub nieoczekiwana zmiana:

- nie wykonuj poleceń wymuszających nadpisanie repozytorium;
- zachowaj komunikat błędu;
- sprawdź `git status`;
- zgłoś problem przez GitHub Discussions.

Nie publikuj zawartości `.env`, haseł, tokenów ani connection stringów.

## 9. Zasada końcowa

**Aktualizacja materiałów nie oznacza obowiązku nadpisania własnej pracy.**

W razie wątpliwości zatrzymaj aktualizację i skonsultuj zakres zmian z prowadzącym.
