#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcja do logowania
log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO")
      echo -e "${BLUE}[INFO]${NC} ${timestamp} - $message"
      ;;
    "SUCCESS")
      echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message"
      ;;
    "WARNING")
      echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
      ;;
    *)
      echo -e "${timestamp} - $message"
      ;;
  esac
  
  # Zapisz logi do pliku
  echo "[$level] $timestamp - $message" >> ./coboarding-min.log
}

# Funkcja do testowania pojedynczego kontenera
test_container() {
  local container_name=$1
  local container_id=$2
  local port=$3
  local endpoint=$4
  local expected=$5
  
  log "INFO" "Testowanie kontenera $container_name na porcie $port..."
  
  # Sprawdź czy kontener działa
  if ! docker ps | grep -q "$container_id"; then
    log "ERROR" "Kontener $container_name nie jest uruchomiony!"
    return 1
  fi
  
  # Sprawdź czy port jest otwarty
  if ! timeout 2 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
    log "ERROR" "Port $port dla kontenera $container_name nie jest dostępny!"
    return 1
  fi
  
  # Jeśli podano endpoint, sprawdź czy zwraca oczekiwaną odpowiedź
  if [ -n "$endpoint" ] && [ -n "$expected" ]; then
    local response=$(curl -s "http://localhost:$port$endpoint")
    if ! echo "$response" | grep -q "$expected"; then
      log "ERROR" "Endpoint $endpoint nie zwrócił oczekiwanej odpowiedzi!"
      log "ERROR" "Otrzymano: $response"
      return 1
    fi
  fi
  
  log "SUCCESS" "Kontener $container_name działa poprawnie!"
  return 0
}

# Funkcja do sprawdzania statusu usługi
check_service_status() {
  local service_name=$1
  local container_name=$2
  
  log "INFO" "Sprawdzanie statusu usługi $service_name..."
  
  if docker ps | grep -q "$container_name"; then
    local status=$(docker inspect --format='{{.State.Status}}' "$container_name")
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}brak{{end}}' "$container_name")
    local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_name")
    
    log "INFO" "Status kontenera $container_name: $status"
    log "INFO" "Stan zdrowia: $health"
    log "INFO" "Uruchomiony od: $uptime"
    
    # Sprawdź logi pod kątem błędów
    local logs=$(docker logs "$container_name" 2>&1)
    if echo "$logs" | grep -i -E "error|exception|failed" | grep -v "DEBUG" > /dev/null; then
      log "WARNING" "Znaleziono potencjalne błędy w logach kontenera $container_name:"
      echo "$logs" | grep -i -E "error|exception|failed" | grep -v "DEBUG" | head -5
    fi
    
    return 0
  else
    log "ERROR" "Kontener $container_name nie jest uruchomiony!"
    return 1
  fi
}

# Funkcja do naprawy usługi
repair_service() {
  local service_name=$1
  
  log "WARNING" "Próba naprawy usługi $service_name..."
  
  # Zatrzymanie i ponowne uruchomienie usługi
  docker-compose -f docker-compose.min.yml stop "$service_name"
  docker-compose -f docker-compose.min.yml up -d "$service_name"
  
  # Sprawdzenie czy usługa została naprawiona
  sleep 5
  if docker ps | grep -q "$service_name"; then
    log "SUCCESS" "Usługa $service_name została naprawiona!"
    return 0
  else
    log "ERROR" "Nie udało się naprawić usługi $service_name!"
    return 1
  fi
}

# Funkcja do otwierania przeglądarki
open_browser() {
  local url="$1"
  log "INFO" "Otwieranie przeglądarki: $url"

  # Wykrywanie systemu operacyjnego i otwieranie URL w przeglądarce
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$url" &>/dev/null &
    elif command -v gnome-open &>/dev/null; then
      gnome-open "$url" &>/dev/null &
    else
      log "WARNING" "Nie można automatycznie otworzyć przeglądarki. Otwórz ręcznie URL: $url"
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url" &>/dev/null &
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    start "" "$url" &>/dev/null &
  else
    log "WARNING" "Nieobsługiwany system. Otwórz URL ręcznie: $url"
    return 1
  fi

  # Daj przeglądarce czas na otwarcie
  sleep 3
  return 0
}

# Inicjalizacja pliku logów
> ./coboarding-min.log
log "INFO" "=== Uruchamianie coBoarding - Minimalna Wersja ==="
log "INFO" "Minimalna wersja coBoarding z prostym modelem LLM (TinyLlama-1.1B)"
log "INFO" "Ta wersja zawiera tylko podstawowe funkcje:"
log "INFO" "- Prosty model LLM działający na CPU (do 2B parametrów)"
log "INFO" "- Przeglądarka dostępna przez noVNC"
log "INFO" "- Brak menedżerów haseł, pipelines i sterowania głosowego"
log "INFO" "- Zoptymalizowane cacheowanie paczek"
log "INFO" "- Kwantyzacja int8 dla mniejszego zużycia pamięci"
log "INFO" "- Limity zasobów dla kontenerów"

# Włączenie BuildKit dla szybszego budowania
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
log "INFO" "Włączono BuildKit dla szybszego budowania"

# Sprawdzenie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    log "ERROR" "Docker nie jest zainstalowany. Instaluję Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Nie udało się zainstalować Dockera. Przerywam."
        exit 1
    else
        log "SUCCESS" "Docker zainstalowany pomyślnie."
    fi
else
    log "INFO" "Docker jest już zainstalowany."
    docker_version=$(docker --version)
    log "INFO" "Wersja Docker: $docker_version"
fi

# Sprawdzenie czy Docker Compose jest zainstalowany
if ! command -v docker-compose &> /dev/null; then
    log "ERROR" "Docker Compose nie jest zainstalowany. Instaluję Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    if ! command -v docker-compose &> /dev/null; then
        log "ERROR" "Nie udało się zainstalować Docker Compose. Przerywam."
        exit 1
    else
        log "SUCCESS" "Docker Compose zainstalowany pomyślnie."
    fi
else
    log "INFO" "Docker Compose jest już zainstalowany."
    compose_version=$(docker-compose --version)
    log "INFO" "Wersja Docker Compose: $compose_version"
fi

# Sprawdzenie czy Docker działa
if ! docker info &>/dev/null; then
    log "ERROR" "Usługa Docker nie jest uruchomiona. Próba uruchomienia..."
    sudo systemctl start docker
    
    if ! docker info &>/dev/null; then
        log "ERROR" "Nie udało się uruchomić usługi Docker. Przerywam."
        exit 1
    else
        log "SUCCESS" "Usługa Docker uruchomiona pomyślnie."
    fi
else
    log "INFO" "Usługa Docker jest uruchomiona."
fi

# Tworzenie katalogów dla wolumenów
log "INFO" "Tworzenie katalogów dla wolumenów..."
mkdir -p ./volumes/models ./volumes/config ./volumes/recordings
log "SUCCESS" "Katalogi dla wolumenów utworzone."

# Sprawdzenie czy wolumen pip-cache istnieje
if ! docker volume inspect coboarding-pip-cache &>/dev/null; then
    log "INFO" "Tworzenie wolumenu pip-cache dla optymalizacji cacheowania..."
    docker volume create coboarding-pip-cache
    log "SUCCESS" "Wolumen pip-cache utworzony."
else
    log "INFO" "Wolumen pip-cache już istnieje."
    # Sprawdzenie rozmiaru wolumenu
    volume_path=$(docker volume inspect coboarding-pip-cache -f '{{ .Mountpoint }}')
    volume_size=$(du -sh "$volume_path" 2>/dev/null | cut -f1)
    log "INFO" "Rozmiar wolumenu pip-cache: $volume_size"
fi

# Sprawdzenie dostępnej pamięci
MEM_TOTAL=$(free -g | awk '/^Mem:/{print $2}')
log "INFO" "Dostępna pamięć: ${MEM_TOTAL}GB"

if [ "$MEM_TOTAL" -lt 4 ]; then
    log "WARNING" "Dostępna pamięć poniżej 4GB. Wydajność może być ograniczona."
    # Zmniejszamy limity pamięci dla kontenerów
    sed -i 's/memory: 2G/memory: 1G/g' docker-compose.min.yml
    sed -i 's/memory: 1G/memory: 512M/g' docker-compose.min.yml
    sed -i 's/memory: 256M/memory: 128M/g' docker-compose.min.yml
    log "INFO" "Limity pamięci zostały automatycznie zmniejszone."
fi

# Sprawdzenie czy model jest dostępny
if [ ! -d "./volumes/models/tinyllama" ]; then
    log "WARNING" "Model TinyLlama nie jest dostępny. Zostanie pobrany podczas pierwszego uruchomienia."
    log "WARNING" "Pierwsze uruchomienie może potrwać dłużej ze względu na pobieranie modelu."
else
    log "INFO" "Model TinyLlama jest dostępny lokalnie."
    model_size=$(du -sh ./volumes/models/tinyllama 2>/dev/null | cut -f1)
    log "INFO" "Rozmiar modelu: $model_size"
fi

# Zatrzymanie istniejących kontenerów, jeśli istnieją
log "INFO" "Zatrzymywanie istniejących kontenerów, jeśli istnieją..."
docker-compose -f docker-compose.min.yml down 2>/dev/null
log "INFO" "Istniejące kontenery zatrzymane."

# Czyszczenie nieużywanych obrazów i wolumenów dla oszczędności miejsca
log "INFO" "Czyszczenie nieużywanych zasobów Docker..."
docker system prune -f --volumes 2>/dev/null
log "INFO" "Nieużywane zasoby Docker wyczyszczone."

# Testowanie komponentów przed uruchomieniem
log "INFO" "Testowanie komponentów przed uruchomieniem..."
if [ -f "./scripts/test_all.sh" ]; then
    log "INFO" "Uruchamianie testów komponentów..."
    chmod +x ./scripts/test_all.sh
    ./scripts/test_all.sh
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        log "SUCCESS" "Testy komponentów zakończone pomyślnie."
    else
        log "WARNING" "Niektóre testy komponentów zakończone niepowodzeniem. Kontynuowanie mimo to..."
    fi
else
    log "WARNING" "Skrypt testowy nie jest dostępny. Pomijanie testów komponentów."
fi

# Budowanie i uruchamianie kontenerów
log "INFO" "Budowanie i uruchamianie kontenerów..."
log "INFO" "Pierwsze uruchomienie może potrwać dłużej, kolejne będą szybsze dzięki cache."

# Uruchamianie z obsługą błędów
docker-compose -f docker-compose.min.yml up --build -d
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    log "ERROR" "Wystąpił błąd podczas budowania kontenerów."
    log "INFO" "Próba uruchomienia kontenerów pojedynczo..."
    
    # Próba uruchomienia każdego kontenera osobno
    docker-compose -f docker-compose.min.yml up -d llm-orchestrator-min
    if [ $? -ne 0 ]; then
        log "ERROR" "Nie udało się uruchomić kontenera llm-orchestrator-min."
    else
        log "SUCCESS" "Kontener llm-orchestrator-min uruchomiony pomyślnie."
    fi
    
    docker-compose -f docker-compose.min.yml up -d browser-service
    if [ $? -ne 0 ]; then
        log "ERROR" "Nie udało się uruchomić kontenera browser-service."
    else
        log "SUCCESS" "Kontener browser-service uruchomiony pomyślnie."
    fi
    
    docker-compose -f docker-compose.min.yml up -d novnc
    if [ $? -ne 0 ]; then
        log "ERROR" "Nie udało się uruchomić kontenera novnc."
    else
        log "SUCCESS" "Kontener novnc uruchomiony pomyślnie."
    fi
else
    log "SUCCESS" "Wszystkie kontenery uruchomione pomyślnie."
fi

# Sprawdzenie statusu kontenerów
log "INFO" "Sprawdzanie statusu kontenerów..."
docker-compose -f docker-compose.min.yml ps

# Sprawdzanie statusu poszczególnych usług
check_service_status "LLM Orchestrator" "llm-orchestrator-min"
LLM_STATUS=$?

check_service_status "Browser Service" "browser-service"
BROWSER_STATUS=$?

check_service_status "noVNC" "novnc"
NOVNC_STATUS=$?

# Próba naprawy usług, które nie działają
if [ $LLM_STATUS -ne 0 ]; then
    log "WARNING" "Usługa LLM Orchestrator nie działa poprawnie. Próba naprawy..."
    repair_service "llm-orchestrator-min"
fi

if [ $BROWSER_STATUS -ne 0 ]; then
    log "WARNING" "Usługa Browser Service nie działa poprawnie. Próba naprawy..."
    repair_service "browser-service"
fi

if [ $NOVNC_STATUS -ne 0 ]; then
    log "WARNING" "Usługa noVNC nie działa poprawnie. Próba naprawy..."
    repair_service "novnc"
fi

# Czekanie na uruchomienie usług
log "INFO" "Czekanie na uruchomienie usług..."
log "INFO" "Sprawdzanie statusu API LLM..."

# Sprawdzanie, czy API jest gotowe
MAX_RETRIES=30
RETRY_COUNT=0
API_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -s http://localhost:5000/api/health | grep -q "status.*ok"; then
    API_READY=true
    break
  fi
  echo -n "."
  RETRY_COUNT=$((RETRY_COUNT+1))
  sleep 2
done

echo ""

if [ "$API_READY" = true ]; then
  log "SUCCESS" "API LLM jest gotowe!"
  
  # Test generowania tekstu
  log "INFO" "Testowanie generowania tekstu..."
  TEST_RESPONSE=$(curl -s -X POST http://localhost:5000/api/generate \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Hello, how are you?", "max_length": 50}')
  
  if [[ $TEST_RESPONSE == *"response"* && $TEST_RESPONSE == *"success"* ]]; then
    log "SUCCESS" "Test generowania tekstu zakończony pomyślnie."
    TEST_ANSWER=$(echo $TEST_RESPONSE | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
    log "INFO" "Przykładowa odpowiedź: $TEST_ANSWER"
  else
    log "ERROR" "Test generowania tekstu zakończony niepowodzeniem."
    log "ERROR" "Odpowiedź: $TEST_RESPONSE"
  fi
else
  log "ERROR" "API LLM nie jest gotowe po czasie oczekiwania."
fi

# Sprawdzenie czy VNC jest dostępny
log "INFO" "Sprawdzanie czy VNC jest dostępny..."
if nc -z localhost 5900 2>/dev/null; then
  log "SUCCESS" "VNC jest dostępny na porcie 5900."
  VNC_READY=true
else
  log "ERROR" "VNC nie jest dostępny na porcie 5900."
  VNC_READY=false
fi

# Sprawdzenie czy noVNC jest dostępny
log "INFO" "Sprawdzanie czy noVNC jest dostępny..."
if curl -s http://localhost:8080 | grep -q "noVNC"; then
  log "SUCCESS" "noVNC jest dostępny na porcie 8080."
  NOVNC_READY=true
else
  log "ERROR" "noVNC nie jest dostępny na porcie 8080."
  NOVNC_READY=false
fi

# Testowanie pełnej integracji
log "INFO" "Testowanie pełnej integracji komponentów..."

# Sprawdzenie czy wszystkie usługi są dostępne
if [ "$API_READY" = true ] && [ "$VNC_READY" = true ] && [ "$NOVNC_READY" = true ]; then
  log "SUCCESS" "Wszystkie usługi są dostępne i działają poprawnie!"
  INTEGRATION_OK=true
else
  log "WARNING" "Nie wszystkie usługi są dostępne. Niektóre funkcje mogą nie działać poprawnie."
  INTEGRATION_OK=false
  
  # Wyświetlenie statusu poszczególnych usług
  if [ "$API_READY" != true ]; then
    log "ERROR" "API LLM nie jest dostępne."
  fi
  
  if [ "$VNC_READY" != true ]; then
    log "ERROR" "VNC nie jest dostępne."
  fi
  
  if [ "$NOVNC_READY" != true ]; then
    log "ERROR" "noVNC nie jest dostępne."
  fi
fi

# Otwieranie noVNC w przeglądarce
if [ "$NOVNC_READY" = true ]; then
  log "INFO" "Otwieranie noVNC w przeglądarce..."
  open_browser "http://localhost:8080/vnc.html?autoconnect=true&password=secret"
else
  log "WARNING" "noVNC nie jest dostępne. Nie można otworzyć przeglądarki."
fi

log "INFO" "=== coBoarding - Minimalna Wersja uruchomiona ==="
log "INFO" "noVNC dostępny pod adresem: http://localhost:8080/vnc.html?autoconnect=true&password=secret"
log "INFO" "API LLM dostępne pod adresem: http://localhost:5000"

# Wyświetlanie informacji o zużyciu zasobów
log "INFO" "Informacje o zużyciu zasobów:"
docker stats --no-stream

# Podsumowanie
if [ "$INTEGRATION_OK" = true ]; then
  log "SUCCESS" "Środowisko coBoarding Minimal zostało pomyślnie uruchomione i przetestowane."
  log "SUCCESS" "Wszystkie komponenty działają poprawnie."
else
  log "WARNING" "Środowisko coBoarding Minimal zostało uruchomione, ale niektóre komponenty mogą nie działać poprawnie."
  log "WARNING" "Sprawdź logi, aby uzyskać więcej informacji."
fi

log "INFO" "Aby zatrzymać, użyj: docker-compose -f docker-compose.min.yml down"
log "INFO" "Informacja o cache: Paczki Pythona są przechowywane w wolumenie Docker 'coboarding-pip-cache'"
log "INFO" "Dzięki temu kolejne uruchomienia będą znacznie szybsze."
log "INFO" "Optymalizacje: Kwantyzacja int8, limity pamięci, BuildKit, cacheowanie paczek"
log "INFO" "Logi zostały zapisane w pliku: ./coboarding-min.log"
