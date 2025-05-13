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

## Monitorowanie systemu

Aby monitorować stan usług i postęp ładowania modelu LLM, możesz użyć skryptu `monitor.sh`:

```bash
./monitor.sh
```

Skrypt ten dostarcza informacje o:
- Statusie wszystkich kontenerów
- Postępie ładowania modelu LLM
- Dostępności API
- Zużyciu zasobów (CPU, pamięć)
- Logach z kontenerów

### Opcje monitorowania

Skrypt oferuje różne tryby działania:

```bash
# Monitorowanie w czasie rzeczywistym (aktualizacja co 5 sekund)
./monitor.sh --live

# Wyświetlenie tylko podsumowania statusu
./monitor.sh --summary

# Monitorowanie procesu ładowania modelu
./monitor.sh --model

# Monitorowanie statusu API
./monitor.sh --api

# Informacje o sieci i połączeniach między kontenerami
./monitor.sh --network

# Status środowiska testowego (noVNC i przeglądarka)
./monitor.sh --novnc

# Statystyki zużycia zasobów przez kontenery
./monitor.sh --containers

# Wyświetlenie wszystkich dostępnych opcji
./monitor.sh --help
```

Użyj opcji `--model`, aby śledzić postęp ładowania modelu LLM i sprawdzić, czy komunikat "Service Unavailable" jest spowodowany tym, że model jest jeszcze w trakcie ładowania.

## Rozwiązywanie problemów

### Problem z uruchomieniem kontenerów

Jeśli występują problemy z uruchomieniem kontenerów za pomocą `run.sh`, użyj alternatywnego skryptu:

```bash
./reset_and_run.sh
```

Ten skrypt całkowicie resetuje środowisko Docker i uruchamia kontenery ręcznie, co pomaga rozwiązać problemy z kompatybilnością Docker/docker-compose.

### Problem z ładowaniem modelu

Jeśli w logach kontenera `llm-model-service` pojawia się błąd związany z ładowaniem modelu (np. `OSError: Unable to load weights from pytorch checkpoint file`), użyj skryptu naprawczego:

```bash
sudo ./fix_model_service.sh
```

Ten skrypt:
1. Zatrzymuje i usuwa kontener `llm-model-service`
2. Pobiera wszystkie niezbędne pliki modelu TinyLlama z HuggingFace
3. Ustawia odpowiednie uprawnienia dla katalogu `models`
4. Uruchamia ponownie kontener `llm-model-service`

Po uruchomieniu skryptu, możesz monitorować postęp ładowania modelu za pomocą:

```bash
./monitor.sh --model --live
```

### Problem z dostępem do API

Jeśli podczas testów otrzymujesz odpowiedź "Service Unavailable", może to oznaczać, że:

1. Model LLM jest jeszcze w trakcie ładowania (może to potrwać kilka minut)
2. Kontener `llm-model-service` nie działa poprawnie

Aby sprawdzić status modelu i API, użyj:

```bash
./monitor.sh --summary
```

Jeśli status modelu jest "Nieznany" lub "Ładowanie", poczekaj kilka minut. Jeśli problem nie ustępuje, użyj skryptu naprawczego:

```bash
sudo ./fix_model_service.sh
```

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
