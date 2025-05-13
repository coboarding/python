# Testowanie systemu LLM z przeglądarką i noVNC

Ten dokument opisuje procedurę testowania systemu LLM z wykorzystaniem przeglądarki internetowej i noVNC. Pozwala to na wygodne testowanie API i generowanie tekstu bez konieczności instalowania dodatkowych narzędzi na komputerze lokalnym.

## Wymagania

- Docker
- Dostęp do internetu (do pobierania obrazów Docker)
- Minimum 4GB RAM dla kontenera modelu LLM

## Szybki start

System można uruchomić na trzy różne sposoby, w zależności od potrzeb:

### 1. Standardowe uruchomienie (zalecane)

```bash
./run.sh
```

Ten skrypt automatycznie:
- Sprawdza wymagania systemowe (Docker, docker-compose)
- Wykonuje migrację do mikrousług, jeśli nie została jeszcze wykonana
- Tworzy sieć Docker dla komunikacji między kontenerami
- Buduje i uruchamia mikrousługi (model-service i api-gateway)
- Konfiguruje środowisko testowe z noVNC i przeglądarką Firefox
- Przeprowadza testy API, aby upewnić się, że system działa poprawnie
- Wyświetla instrukcje dla użytkownika

### 2. Resetowanie i ręczne uruchomienie (w przypadku problemów)

```bash
./reset_and_run.sh
```

Ten skrypt jest przydatny, gdy występują problemy z uruchomieniem standardowym:
- Całkowicie resetuje środowisko Docker (usuwa wszystkie kontenery, obrazy i sieci związane z projektem)
- Ręcznie buduje i uruchamia kontenery, pomijając docker-compose
- Jest bardziej niezawodny w przypadku problemów z kompatybilnością Docker/docker-compose

### 3. Konfiguracja tylko środowiska testowego

```bash
./setup_novnc_test.sh
```

Ten skrypt konfiguruje tylko środowisko testowe z noVNC i przeglądarką, zakładając że mikrousługi są już uruchomione.

## Zatrzymanie systemu

Aby zatrzymać i usunąć wszystkie kontenery:

```bash
./stop.sh
```

Ten skrypt:
- Zatrzymuje i usuwa wszystkie kontenery mikrousług
- Zatrzymuje i usuwa kontenery środowiska testowego (noVNC, przeglądarka)
- Usuwa sieć Docker
- Pyta użytkownika, czy chce usunąć katalog cache i wolumeny

## Dostęp do środowiska testowego

Po uruchomieniu systemu:

1. Otwórz przeglądarkę i przejdź do adresu:
   ```
   http://localhost:6080
   ```

2. Zaloguj się do noVNC używając hasła:
   ```
   password
   ```

3. W przeglądarce Firefox wewnątrz noVNC, otwórz plik:
   ```
   file:///config/test_llm.html
   ```

4. Możesz teraz testować API LLM:
   - Wprowadź prompt w polu tekstowym
   - Dostosuj parametry (temperatura, maksymalna długość)
   - Kliknij "Generuj tekst"

## Testowanie API bezpośrednio

Możesz również testować API bezpośrednio:

1. Sprawdzenie statusu API:
   ```bash
   curl http://localhost/api/health
   ```

2. Generowanie tekstu:
   ```bash
   curl -X POST http://localhost/api/generate \
     -H "Content-Type: application/json" \
     -d '{"prompt":"Opowiedz mi krótką historię o kocie.", "max_length":256, "temperature":0.7}'
   ```

## Monitorowanie

Dashboard Traefik jest dostępny pod adresem:
```
http://localhost:8080
```

Pozwala on na monitorowanie statusu mikrousług i ruchu sieciowego.

## Rozwiązywanie problemów

### Problem z uruchomieniem kontenerów

Jeśli występują problemy z uruchomieniem kontenerów za pomocą `run.sh`, spróbuj użyć skryptu `reset_and_run.sh`, który całkowicie resetuje środowisko Docker i uruchamia kontenery ręcznie.

### Błąd "ContainerConfig"

Jeśli pojawia się błąd `KeyError: 'ContainerConfig'`, jest to problem z kompatybilnością między wersjami Docker i docker-compose. Użyj skryptu `reset_and_run.sh`, który omija ten problem.

### API zwraca "Service Unavailable"

Po uruchomieniu systemu, model LLM potrzebuje czasu na załadowanie (zwykle kilka minut). W tym czasie API może zwracać "Service Unavailable". Poczekaj kilka minut i spróbuj ponownie.

### Problemy z pamięcią

Model LLM wymaga minimum 4GB RAM. Jeśli kontener model-service ulega awarii, sprawdź dostępną pamięć i w razie potrzeby zwiększ limit w pliku `docker-compose.yml`.

## Struktura katalogów

```
llm-orchestrator-min/
├── docker-compose.yml           # Konfiguracja mikrousług
├── run.sh                       # Skrypt do standardowego uruchomienia
├── reset_and_run.sh             # Skrypt do resetowania i ręcznego uruchomienia
├── stop.sh                      # Skrypt do zatrzymania systemu
├── setup_novnc_test.sh          # Skrypt do konfiguracji środowiska testowego
├── microservices/               # Katalog z mikrousługami
│   ├── api-gateway/             # Brama API (Traefik)
│   └── model-service/           # Usługa modelu LLM
├── models/                      # Katalog na pliki modeli
└── .cache/                      # Katalog cache
    ├── pip/                     # Cache pakietów pip
    └── models/                  # Cache pobranych modeli
```

## Architektura systemu

System składa się z następujących komponentów:

1. **model-service**: Mikrousługa odpowiedzialna za ładowanie modelu LLM i generowanie tekstu
2. **api-gateway**: Brama API (Traefik) odpowiedzialna za routing żądań
3. **noVNC**: Serwer VNC dostępny przez przeglądarkę
4. **browser**: Kontener z przeglądarką Firefox

Komunikacja między komponentami odbywa się przez sieć Docker `llm-network`.

## Konfiguracja

Główne parametry konfiguracyjne:

- **MODEL_PATH**: Ścieżka do plików modelu (domyślnie: `/app/models/tinyllama`)
- **USE_INT8**: Flaga włączająca kwantyzację INT8 (domyślnie: `true`)
- **MODEL_SERVICE_PORT**: Port, na którym nasłuchuje usługa modelu (domyślnie: `5000`)
