# Szybki start z llm-orchestrator-min

Ten dokument zawiera instrukcje uruchomienia minimalnej wersji orkiestratora LLM, która jest lżejszą alternatywą dla pełnej wersji systemu.

## Wymagania wstępne

- Docker
- Git
- Bash (dla skryptów pomocniczych)

## Szybkie uruchomienie

Aby szybko uruchomić minimalną wersję orkiestratora LLM, wykonaj następujące kroki:

```bash
# Sklonuj repozytorium (jeśli jeszcze tego nie zrobiłeś)
git clone https://github.com/coboarding/python.git
cd python/containers/llm-orchestrator-min

# Zbuduj i uruchom kontener
./scripts/manage_container.sh build
./scripts/manage_container.sh run [opcjonalny_port]  # domyślnie 5000
```

Po uruchomieniu, API będzie dostępne pod adresem `http://localhost:[port]/api/`.

## Testowanie

Aby przetestować API po uruchomieniu:

```bash
# Uruchom podstawowe testy
./scripts/run_tests_after_startup.sh --url=http://localhost:[port]

# Lub uruchom kompleksowe testy
python3 ./scripts/comprehensive_test.py --url=http://localhost:[port]
```

## Struktura projektu

```
llm-orchestrator-min/
├── api.py                  # Główny plik API
├── Dockerfile              # Definicja kontenera
├── requirements.txt        # Zależności Pythona
├── docs/                   # Dokumentacja
│   ├── TESTING.md          # Szczegółowa dokumentacja testów
│   └── QUICKSTART.md       # Ten dokument
└── scripts/                # Skrypty pomocnicze
    ├── manage_container.sh # Zarządzanie kontenerem
    ├── test_api.sh         # Podstawowe testy API
    └── ...
```

## Rozwiązywanie problemów

Jeśli napotkasz problemy podczas uruchamiania kontenera:

1. **Port jest już zajęty**: Użyj innego portu w poleceniu `./scripts/manage_container.sh run [inny_port]`
2. **Problemy z budowaniem**: Sprawdź logi budowania: `docker logs $(docker ps -a | grep llm-orchestrator-min | awk '{print $1}')`
3. **API nie odpowiada**: Uruchom skrypt diagnostyczny: `./scripts/diagnose_api.sh`

## Konfiguracja

Możesz dostosować działanie API poprzez zmienne środowiskowe:

- `API_PORT`: Port, na którym działa API (domyślnie 5000)
- `USE_INT8`: Używaj kwantyzacji INT8 dla modelu (domyślnie true)

Przykład:
```bash
docker run -e API_PORT=8080 -e USE_INT8=false -p 8080:8080 llm-orchestrator-min
```

## Rozwój

Aby dowiedzieć się więcej o testowaniu i rozwoju, zapoznaj się z dokumentem [TESTING.md](./TESTING.md).
