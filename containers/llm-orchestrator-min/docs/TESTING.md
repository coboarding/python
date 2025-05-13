# Dokumentacja Testowania API LLM-Orchestrator-Min

## Spis treści
1. [Wprowadzenie](#wprowadzenie)
2. [Przygotowanie środowiska](#przygotowanie-środowiska)
3. [Dostępne narzędzia testowe](#dostępne-narzędzia-testowe)
4. [Uruchamianie testów](#uruchamianie-testów)
5. [Testy obciążeniowe](#testy-obciążeniowe)
6. [Automatyzacja testów](#automatyzacja-testów)
7. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
8. [Najlepsze praktyki](#najlepsze-praktyki)

## Wprowadzenie

Ten dokument opisuje procedury testowania API LLM-Orchestrator-Min, które pozwalają na weryfikację poprawności działania, wydajności oraz stabilności usługi. Testy są kluczowym elementem zapewnienia jakości i powinny być uruchamiane po każdej znaczącej zmianie w kodzie lub konfiguracji.

## Przygotowanie środowiska

Przed uruchomieniem testów upewnij się, że:

1. Kontener `llm-orchestrator-min` jest zbudowany i uruchomiony
2. API jest dostępne pod oczekiwanym adresem (domyślnie: `http://localhost:5000`)
3. Model TinyLlama został poprawnie pobrany i załadowany

Możesz użyć skryptu zarządzającego do przygotowania środowiska:

```bash
# Budowanie kontenera z optymalizacjami cache
./scripts/manage_container.sh build

# Uruchamianie kontenera
./scripts/manage_container.sh run
```

## Dostępne narzędzia testowe

W projekcie dostępne są następujące narzędzia testowe:

1. **Podstawowy tester API** (`scripts/test_api.sh`)
   - Prosty skrypt bash do testowania podstawowych endpointów API
   - Sprawdza dostępność i podstawową funkcjonalność

2. **Kompleksowy tester API** (`scripts/comprehensive_test.py`)
   - Zaawansowany tester napisany w Pythonie
   - Umożliwia przeprowadzenie testów funkcjonalnych i obciążeniowych
   - Generuje szczegółowe raporty

3. **Narzędzia do analizy jakości kodu** (`scripts/code_quality.sh`)
   - Uruchamia narzędzia takie jak black, flake8, pylint, mypy i isort
   - Pomaga utrzymać wysoką jakość kodu

4. **Tox** (konfiguracja w `tox.ini`)
   - Umożliwia testowanie w izolowanych środowiskach
   - Automatyzuje uruchamianie testów jednostkowych i linterów

## Uruchamianie testów

### Podstawowe testy API

```bash
# Uruchomienie podstawowych testów API
./scripts/test_api.sh

# Lub za pomocą skryptu zarządzającego
./scripts/manage_container.sh test
```

### Kompleksowe testy API

```bash
# Uruchomienie kompleksowych testów API
python ./scripts/comprehensive_test.py --url http://localhost:5000 --verbose

# Zapisanie wyników do pliku JSON
python ./scripts/comprehensive_test.py --output results.json
```

### Testy jakości kodu

```bash
# Analiza jakości kodu
./scripts/code_quality.sh

# Automatyczne naprawianie problemów z formatowaniem
./scripts/code_quality.sh --fix
```

### Testy z użyciem tox

```bash
# Uruchomienie wszystkich testów zdefiniowanych w tox.ini
tox

# Uruchomienie tylko testów jednostkowych
tox -e py39

# Uruchomienie tylko linterów
tox -e lint
```

## Testy obciążeniowe

Testy obciążeniowe pozwalają sprawdzić jak API radzi sobie z wieloma równoczesnymi żądaniami:

```bash
# Uruchomienie testów obciążeniowych (domyślnie: 2 równoczesne żądania, 5 łącznie)
python ./scripts/comprehensive_test.py --load-test

# Dostosowanie parametrów testów obciążeniowych
python ./scripts/comprehensive_test.py --load-test --concurrency 5 --requests 20
```

Parametry testów obciążeniowych:
- `--concurrency` - liczba równoczesnych żądań (domyślnie: 2)
- `--requests` - łączna liczba żądań do wykonania (domyślnie: 5)

## Automatyzacja testów

Testy mogą być automatycznie uruchamiane po uruchomieniu kontenera za pomocą skryptu `run_tests_after_startup.sh`. Skrypt ten:

1. Czeka na pełne uruchomienie API
2. Uruchamia podstawowe testy API
3. Uruchamia kompleksowe testy API (opcjonalnie)
4. Generuje raport z testów

Aby uruchomić automatyczne testy po starcie kontenera:

```bash
./scripts/run_tests_after_startup.sh
```

## Rozwiązywanie problemów

Jeśli testy nie przechodzą, wykonaj następujące kroki:

1. Sprawdź logi kontenera:
   ```bash
   docker logs llm-orchestrator-min
   ```

2. Uruchom diagnostykę:
   ```bash
   ./scripts/manage_container.sh diagnose
   ```

3. Spróbuj naprawić typowe problemy:
   ```bash
   ./scripts/manage_container.sh fix
   ```

4. Sprawdź, czy model został poprawnie pobrany:
   ```bash
   docker exec llm-orchestrator-min ls -la /app/models/tinyllama
   ```

## Najlepsze praktyki

1. **Regularnie uruchamiaj testy** - po każdej znaczącej zmianie w kodzie
2. **Automatyzuj testy** - używaj CI/CD do automatycznego uruchamiania testów
3. **Monitoruj wydajność** - śledź czasy odpowiedzi API w czasie
4. **Testuj na różnych konfiguracjach** - sprawdzaj działanie z różnymi parametrami
5. **Aktualizuj testy** - dodawaj nowe przypadki testowe wraz z rozwojem API
