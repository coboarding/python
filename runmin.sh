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
  sleep 1
  return 0
}

# Funkcja do sprawdzania i tworzenia wolumenów Docker
check_and_create_volumes() {
  log "INFO" "Sprawdzanie wolumenów Docker..."
  
  # Lista wolumenów do sprawdzenia
  local volumes=("coboarding-pip-cache" "coboarding-wheel-cache" "coboarding-models-cache" "coboarding-chrome-cache")
  
  for volume in "${volumes[@]}"; do
    if ! docker volume inspect "$volume" &>/dev/null; then
      log "INFO" "Tworzenie wolumenu $volume..."
      docker volume create "$volume"
      log "SUCCESS" "Wolumen $volume utworzony."
    else
      # Sprawdzenie rozmiaru wolumenu
      local volume_path=$(docker volume inspect "$volume" -f '{{ .Mountpoint }}')
      local volume_size=$(du -sh "$volume_path" 2>/dev/null | cut -f1)
      log "INFO" "Wolumen $volume już istnieje. Rozmiar: $volume_size"
    fi
  done
}

# Funkcja do zapisywania obrazów Docker do cache
save_docker_images() {
  log "INFO" "Zapisywanie obrazów Docker do cache..."
  
  # Lista obrazów do zapisania
  local images=("llm-orchestrator-min" "browser-service" "novnc")
  
  for image in "${images[@]}"; do
    if docker images | grep -q "$image"; then
      log "INFO" "Zapisywanie obrazu $image do cache..."
      docker tag "$image" "$image:latest"
      log "SUCCESS" "Obraz $image zapisany do cache."
    fi
  done
}

# Funkcja do wyświetlania paska postępu
progress_bar() {
  local current=$1
  local total=$2
  local message=$3
  local bar_size=40
  local progress=$((current * bar_size / total))
  local percentage=$((current * 100 / total))
  
  # Tworzenie paska postępu
  local bar="["
  for ((i=0; i<bar_size; i++)); do
    if [ $i -lt $progress ]; then
      bar+="="
    else
      bar+=" "
    fi
  done
  bar+="] ${percentage}%"
  
  # Wyświetlanie paska postępu
  echo -ne "\r${BLUE}[INFO]${NC} ${message} ${bar}"
  
  # Jeśli to ostatni krok, dodaj nową linię
  if [ $current -eq $total ]; then
    echo ""
  fi
}

# Funkcja do monitorowania zużycia zasobów
monitor_resources() {
  local interval=$1
  local duration=$2
  local output_file="./resource_usage.log"
  
  log "INFO" "Rozpoczęcie monitorowania zużycia zasobów (co ${interval}s przez ${duration}s)"
  echo "Timestamp,Container,CPU%,Memory Usage,Memory Limit,Memory %" > "$output_file"
  
  local end_time=$(($(date +%s) + duration))
  while [ $(date +%s) -lt $end_time ]; do
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" | grep -E 'llm-orchestrator-min|browser-service|novnc' | while IFS=, read -r container cpu mem_usage mem_perc; do
      echo "$(date '+%Y-%m-%d %H:%M:%S'),${container},${cpu},${mem_usage},${mem_perc}" >> "$output_file"
    done
    sleep $interval
  done
  
  log "SUCCESS" "Monitorowanie zużycia zasobów zakończone. Wyniki zapisane w pliku: $output_file"
}

# Funkcja do sprawdzania i czyszczenia nieużywanych obrazów Docker
cleanup_docker_images() {
  log "INFO" "Sprawdzanie nieużywanych obrazów Docker..."
  
  # Liczba nieużywanych obrazów
  local unused_images=$(docker images -f "dangling=true" -q | wc -l)
  
  if [ "$unused_images" -gt 0 ]; then
    log "INFO" "Znaleziono $unused_images nieużywanych obrazów Docker."
    
    # Pytanie użytkownika o zgodę na usunięcie
    read -p "Czy chcesz usunąć nieużywane obrazy Docker? (t/n): " answer
    if [[ "$answer" =~ ^[Tt]$ ]]; then
      log "INFO" "Usuwanie nieużywanych obrazów Docker..."
      docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || log "WARNING" "Nie udało się usunąć niektórych obrazów."
      log "SUCCESS" "Nieużywane obrazy Docker zostały usunięte."
    else
      log "INFO" "Pomijanie usuwania nieużywanych obrazów Docker."
    fi
  else
    log "INFO" "Brak nieużywanych obrazów Docker."
  fi
}

# Funkcja do generowania raportu o stanie systemu
generate_system_report() {
  local report_file="./system_report.txt"
  log "INFO" "Generowanie raportu o stanie systemu..."
  
  {
    echo "=== Raport o stanie systemu coBoarding ==="
    echo "Data wygenerowania: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "=== Informacje o systemie ==="
    echo "System operacyjny: $(uname -s)"
    echo "Wersja jądra: $(uname -r)"
    echo "Architektura: $(uname -m)"
    echo ""
    
    echo "=== Informacje o zasobach ==="
    echo "Procesor:"
    lscpu | grep "Model name" || echo "Nie można uzyskać informacji o procesorze"
    echo "Liczba rdzeni: $(nproc --all)"
    echo ""
    
    echo "Pamięć:"
    free -h || echo "Nie można uzyskać informacji o pamięci"
    echo ""
    
    echo "Dysk:"
    df -h . || echo "Nie można uzyskać informacji o dysku"
    echo ""
    
    echo "=== Informacje o Docker ==="
    echo "Wersja Docker:"
    docker --version || echo "Nie można uzyskać informacji o wersji Docker"
    echo ""
    
    echo "Wersja Docker Compose:"
    docker-compose --version || echo "Nie można uzyskać informacji o wersji Docker Compose"
    echo ""
    
    echo "Uruchomione kontenery:"
    docker ps || echo "Nie można uzyskać informacji o uruchomionych kontenerach"
    echo ""
    
    echo "Wolumeny Docker:"
    docker volume ls | grep "coboarding" || echo "Nie znaleziono wolumenów coBoarding"
    echo ""
    
    echo "=== Informacje o obrazach Docker ==="
    docker images | grep -E 'llm-orchestrator-min|browser-service|novnc' || echo "Nie znaleziono obrazów coBoarding"
    echo ""
    
    echo "=== Informacje o cache ==="
    echo "Rozmiar wolumenu pip-cache:"
    du -sh $(docker volume inspect coboarding-pip-cache -f '{{ .Mountpoint }}') 2>/dev/null || echo "Nie można uzyskać informacji o rozmiarze wolumenu pip-cache"
    echo ""
    
    echo "Rozmiar wolumenu wheel-cache:"
    du -sh $(docker volume inspect coboarding-wheel-cache -f '{{ .Mountpoint }}') 2>/dev/null || echo "Nie można uzyskać informacji o rozmiarze wolumenu wheel-cache"
    echo ""
    
    echo "Rozmiar wolumenu models-cache:"
    du -sh $(docker volume inspect coboarding-models-cache -f '{{ .Mountpoint }}') 2>/dev/null || echo "Nie można uzyskać informacji o rozmiarze wolumenu models-cache"
    echo ""
    
    echo "=== Koniec raportu ==="
  } > "$report_file"
  
  log "SUCCESS" "Raport o stanie systemu został wygenerowany i zapisany w pliku: $report_file"
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

# Parsowanie argumentów wiersza poleceń
SKIP_TESTS=false
FORCE_REBUILD=false
MONITOR_RESOURCES=false
GENERATE_REPORT=false
CLEANUP_IMAGES=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests)
      SKIP_TESTS=true
      log "INFO" "Pomijanie testów komponentów."
      shift
      ;;
    --force-rebuild)
      FORCE_REBUILD=true
      log "INFO" "Wymuszenie przebudowania obrazów Docker."
      shift
      ;;
    --monitor-resources)
      MONITOR_RESOURCES=true
      log "INFO" "Włączono monitorowanie zużycia zasobów."
      shift
      ;;
    --generate-report)
      GENERATE_REPORT=true
      log "INFO" "Włączono generowanie raportu o stanie systemu."
      shift
      ;;
    --cleanup-images)
      CLEANUP_IMAGES=true
      log "INFO" "Włączono czyszczenie nieużywanych obrazów Docker."
      shift
      ;;
    --verbose)
      VERBOSE=true
      log "INFO" "Włączono tryb szczegółowy (verbose)."
      shift
      ;;
    --help)
      echo "Użycie: ./runmin.sh [opcje]"
      echo "Opcje:"
      echo "  --skip-tests           Pomija testy komponentów"
      echo "  --force-rebuild        Wymusza przebudowanie obrazów Docker"
      echo "  --monitor-resources    Włącza monitorowanie zużycia zasobów"
      echo "  --generate-report      Generuje raport o stanie systemu"
      echo "  --cleanup-images       Czyści nieużywane obrazy Docker"
      echo "  --verbose              Włącza tryb szczegółowy (verbose)"
      echo "  --help                 Wyświetla tę pomoc"
      exit 0
      ;;
    *)
      log "ERROR" "Nieznana opcja: $1"
      echo "Użyj --help, aby wyświetlić dostępne opcje."
      exit 1
      ;;
  esac
done

# Wyłączenie BuildKit, ponieważ może nie być dostępny
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
log "INFO" "Wyłączono BuildKit, ponieważ może nie być dostępny w systemie"

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

# Sprawdzenie i utworzenie wolumenów Docker
check_and_create_volumes

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
if [ -d "./volumes/models/tinyllama" ] && [ -f "./volumes/models/tinyllama/pytorch_model.bin" ]; then
    log "INFO" "Model TinyLlama jest dostępny lokalnie."
    model_size=$(du -sh ./volumes/models/tinyllama 2>/dev/null | cut -f1)
    log "INFO" "Rozmiar modelu: $model_size"
else
    log "WARNING" "Model TinyLlama nie jest dostępny lokalnie. Zostanie pobrany podczas pierwszego uruchomienia."
    log "WARNING" "Pierwsze uruchomienie może potrwać dłużej ze względu na pobieranie modelu."
fi

# Sprawdzenie czy obrazy Docker są już zbudowane
log "INFO" "Sprawdzanie czy obrazy Docker są już zbudowane..."
REBUILD_NEEDED=false

if [ "$FORCE_REBUILD" = true ]; then
    log "INFO" "Wymuszono przebudowanie obrazów Docker."
    REBUILD_NEEDED=true
else
    for image in "llm-orchestrator-min" "browser-service" "novnc"; do
        if ! docker images | grep -q "$image"; then
            log "INFO" "Obraz $image nie istnieje, będzie budowany."
            REBUILD_NEEDED=true
        else
            log "INFO" "Obraz $image już istnieje."
            image_id=$(docker images -q "$image")
            image_created=$(docker inspect -f '{{ .Created }}' "$image_id")
            image_size=$(docker inspect -f '{{ .Size }}' "$image_id" | numfmt --to=iec-i --suffix=B)
            log "INFO" "Obraz $image utworzony: $image_created, rozmiar: $image_size"
        fi
    done
fi

# Zatrzymanie istniejących kontenerów, jeśli istnieją
log "INFO" "Zatrzymywanie istniejących kontenerów, jeśli istnieją..."
docker-compose -f docker-compose.min.yml down 2>/dev/null
log "INFO" "Istniejące kontenery zatrzymane."

# Usunięcie argumentów BUILDKIT z docker-compose.min.yml
log "INFO" "Usuwanie argumentów BuildKit z docker-compose.min.yml..."
sed -i '/BUILDKIT_INLINE_CACHE/d' docker-compose.min.yml
log "SUCCESS" "Argumenty BuildKit usunięte."

# Modyfikacja Dockerfile dla kontenera llm-orchestrator-min, aby usunąć zależności NVIDIA
log "INFO" "Modyfikacja Dockerfile dla kontenera llm-orchestrator-min, aby usunąć zależności NVIDIA..."
if [ -f "./containers/llm-orchestrator-min/Dockerfile" ]; then
    # Usunięcie linii związanych z CUDA i NVIDIA
    sed -i '/cuda/d' ./containers/llm-orchestrator-min/Dockerfile
    sed -i '/nvidia/d' ./containers/llm-orchestrator-min/Dockerfile
    sed -i '/GPU/d' ./containers/llm-orchestrator-min/Dockerfile
    log "SUCCESS" "Dockerfile zmodyfikowany - usunięto zależności NVIDIA."
    
    # Modyfikacja requirements.txt, aby usunąć zależności NVIDIA
    if [ -f "./containers/llm-orchestrator-min/requirements.txt" ]; then
        sed -i '/cuda/d' ./containers/llm-orchestrator-min/requirements.txt
        sed -i '/nvidia/d' ./containers/llm-orchestrator-min/requirements.txt
        log "SUCCESS" "requirements.txt zmodyfikowany - usunięto zależności NVIDIA."
    fi
else
    log "WARNING" "Nie znaleziono pliku Dockerfile dla kontenera llm-orchestrator-min."
fi

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

if [ "$REBUILD_NEEDED" = true ]; then
    log "INFO" "Budowanie obrazów Docker od nowa. To może potrwać kilka minut..."
    log "INFO" "Używanie cache dla przyspieszenia procesu budowania."
    
    # Wyświetlanie paska postępu podczas budowania
    if [ "$VERBOSE" = true ]; then
        docker-compose -f docker-compose.min.yml build --pull --no-cache
    else
        log "INFO" "Budowanie obrazu llm-orchestrator-min (1/3)..."
        docker-compose -f docker-compose.min.yml build --pull --no-cache llm-orchestrator-min > /dev/null 2>&1
        progress_bar 1 3 "Budowanie obrazów Docker..."
        
        log "INFO" "Budowanie obrazu browser-service (2/3)..."
        docker-compose -f docker-compose.min.yml build --pull --no-cache browser-service > /dev/null 2>&1
        progress_bar 2 3 "Budowanie obrazów Docker..."
        
        log "INFO" "Budowanie obrazu novnc (3/3)..."
        docker-compose -f docker-compose.min.yml build --pull --no-cache novnc > /dev/null 2>&1
        progress_bar 3 3 "Budowanie obrazów Docker..."
    fi
    
    BUILD_RESULT=$?
    
    if [ $BUILD_RESULT -eq 0 ]; then
        log "SUCCESS" "Obrazy Docker zostały pomyślnie zbudowane."
        
        log "INFO" "Uruchamianie kontenerów..."
        docker-compose -f docker-compose.min.yml up -d
        UP_RESULT=$?
        
        if [ $UP_RESULT -eq 0 ]; then
            log "SUCCESS" "Kontenery zostały pomyślnie uruchomione."
        else
            log "ERROR" "Wystąpił błąd podczas uruchamiania kontenerów."
        fi
    else
        log "ERROR" "Wystąpił błąd podczas budowania obrazów Docker."
    fi
else
    log "INFO" "Używanie istniejących obrazów Docker. Uruchamianie kontenerów..."
    docker-compose -f docker-compose.min.yml up -d
    BUILD_RESULT=$?
fi

# Zapisanie obrazów Docker do cache
save_docker_images

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

# Otwieranie zakładek w przeglądarce dla działających usług
log "INFO" "Otwieranie zakładek w przeglądarce dla działających usług..."

# Otwieranie noVNC w przeglądarce
if [ "$NOVNC_READY" = true ]; then
  log "INFO" "Otwieranie noVNC w przeglądarce..."
  open_browser "http://localhost:8080/vnc.html?autoconnect=true&password=secret"
  sleep 1
fi

# Otwieranie API LLM w przeglądarce
if [ "$API_READY" = true ]; then
  log "INFO" "Otwieranie API LLM w przeglądarce..."
  open_browser "http://localhost:5000/api/docs"
  sleep 1
fi

# Otwieranie strony z dokumentacją w przeglądarce
log "INFO" "Otwieranie strony z dokumentacją w przeglądarce..."
open_browser "http://localhost:5000"

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

log "INFO" "Aby zatrzymać, użyj: ./stop.sh"
log "INFO" "Informacja o cache: Paczki Pythona są przechowywane w wolumenach Docker:"
log "INFO" "- coboarding-pip-cache: główny cache pip"
log "INFO" "- coboarding-wheel-cache: skompilowane pakiety Python"
log "INFO" "- coboarding-models-cache: pobrane modele LLM"
log "INFO" "- coboarding-chrome-cache: cache przeglądarki Chrome"
log "INFO" "Dzięki temu kolejne uruchomienia będą znacznie szybsze."
log "INFO" "Optymalizacje: Kwantyzacja int8, limity pamięci, cacheowanie paczek, zapisywanie obrazów Docker"
log "INFO" "Logi zostały zapisane w pliku: ./coboarding-min.log"

# Uruchomienie dodatkowych funkcji na podstawie argumentów
if [ "$MONITOR_RESOURCES" = true ]; then
  log "INFO" "Uruchamianie monitorowania zużycia zasobów (w tle)..."
  monitor_resources 5 300 &
fi

if [ "$GENERATE_REPORT" = true ]; then
  generate_system_report
fi

if [ "$CLEANUP_IMAGES" = true ]; then
  cleanup_docker_images
fi

log "INFO" "Aby zatrzymać, użyj: ./stop.sh"
log "INFO" "Informacja o cache: Paczki Pythona są przechowywane w wolumenach Docker:"
log "INFO" "- coboarding-pip-cache: główny cache pip"
log "INFO" "- coboarding-wheel-cache: skompilowane pakiety Python"
log "INFO" "- coboarding-models-cache: pobrane modele LLM"
log "INFO" "- coboarding-chrome-cache: cache przeglądarki Chrome"
log "INFO" "Dzięki temu kolejne uruchomienia będą znacznie szybsze."
log "INFO" "Optymalizacje: Kwantyzacja int8, limity pamięci, cacheowanie paczek, zapisywanie obrazów Docker"
log "INFO" "Logi zostały zapisane w pliku: ./coboarding-min.log"

# Wyświetlanie czasu wykonania skryptu
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
log "INFO" "Czas wykonania skryptu: ${EXECUTION_TIME}s"
