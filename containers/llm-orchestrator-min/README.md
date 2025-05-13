# LLM Orchestrator Microservices

System do uruchamiania i testowania modeli językowych (LLM) w architekturze mikrousług z wykorzystaniem Docker.

## Funkcjonalności

- **Architektura mikrousług** - model-service i api-gateway
- **Optymalizacja wydajności** - cachowanie pakietów i modeli
- **Łatwe testowanie** - środowisko testowe z noVNC i przeglądarką
- **Monitorowanie** - dashboard Traefik do monitorowania mikrousług
- **Skalowalność** - możliwość uruchomienia wielu instancji model-service

## Wymagania

- Docker
- docker-compose
- Minimum 4GB RAM dla kontenera modelu LLM
- Dostęp do internetu (do pobierania obrazów Docker i modeli)

## Szybki start

### 1. Uruchomienie systemu

```bash
./run.sh
```

Ten skrypt automatycznie:
- Sprawdza wymagania systemowe
- Wykonuje migrację do mikrousług (jeśli potrzebna)
- Buduje i uruchamia wszystkie kontenery
- Konfiguruje środowisko testowe

### 2. Testowanie systemu

Po uruchomieniu systemu:

1. Otwórz przeglądarkę i przejdź do adresu:
   ```
   http://localhost:6080
   ```

2. Zaloguj się do noVNC używając hasła:
   ```
   password
   ```

3. W przeglądarce Firefox wewnątrz noVNC, otwórz:
   ```
   file:///config/test_llm.html
   ```

### 3. Zatrzymanie systemu

```bash
./stop.sh
```

## Rozwiązywanie problemów

Jeśli występują problemy z uruchomieniem kontenerów za pomocą `run.sh`, użyj alternatywnego skryptu:

```bash
./reset_and_run.sh
```

Ten skrypt całkowicie resetuje środowisko Docker i uruchamia kontenery ręcznie, co pomaga rozwiązać problemy z kompatybilnością Docker/docker-compose.

## Dokumentacja

Szczegółowa dokumentacja jest dostępna w katalogu `docs`:

- [Testowanie z noVNC](docs/NOVNC_TESTING.md) - instrukcje dotyczące testowania systemu z przeglądarką i noVNC
- [Migracja do mikrousług](docs/MICROSERVICES.md) - informacje o migracji do architektury mikrousług
- [Monitorowanie](docs/MONITORING.md) - instrukcje dotyczące monitorowania systemu

## Struktura projektu

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
├── .cache/                      # Katalog cache
│   ├── pip/                     # Cache pakietów pip
│   └── models/                  # Cache pobranych modeli
└── docs/                        # Dokumentacja
```

## Konfiguracja

Główne parametry konfiguracyjne są dostępne w pliku `docker-compose.yml`:

- **MODEL_PATH**: Ścieżka do plików modelu
- **USE_INT8**: Flaga włączająca kwantyzację INT8
- **MODEL_SERVICE_PORT**: Port, na którym nasłuchuje usługa modelu

## Licencja

Ten projekt jest udostępniany na licencji MIT.
