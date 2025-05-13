#!/bin/bash

# Główny skrypt do zarządzania kontenerem llm-orchestrator-min
# Autor: Tom
# Data: 2025-05-13

set -e

# Kolory do lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log() {
  local level=$1
  local message=$2
  
  case $level in
    "INFO")
      echo -e "${GREEN}[INFO]${NC} $message"
      ;;
    "WARN")
      echo -e "${YELLOW}[WARN]${NC} $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
    *)
      echo -e "${BLUE}[DEBUG]${NC} $message"
      ;;
  esac
}

# Funkcja do budowania kontenera z optymalizacjami
build_container() {
  log "INFO" "Budowanie kontenera llm-orchestrator-min z optymalizacjami cache..."
  
  # Sprawdzenie czy BuildKit jest dostępny
  if docker buildx version &>/dev/null; then
    log "INFO" "Używam BuildKit do budowania kontenera"
    export DOCKER_BUILDKIT=1
    
    # Tworzenie wolumenów cache jeśli nie istnieją
    docker volume create coboarding-pip-cache &>/dev/null || true
    docker volume create coboarding-wheel-cache &>/dev/null || true
    
    # Budowanie z wykorzystaniem BuildKit i cache
    cd /home/tom/github/coboarding/python
    docker buildx build \
      --build-arg BUILDKIT_INLINE_CACHE=1 \
      --cache-from llm-orchestrator-min:latest \
      --tag llm-orchestrator-min:latest \
      --file containers/llm-orchestrator-min/Dockerfile \
      .
  else
    log "WARN" "BuildKit nie jest dostępny, używam standardowego buildera Docker"
    cd /home/tom/github/coboarding/python
    docker build \
      -t llm-orchestrator-min:latest \
      -f containers/llm-orchestrator-min/Dockerfile \
      .
  fi
  
  log "INFO" "Kontener zbudowany pomyślnie"
}

# Funkcja do uruchamiania kontenera
run_container() {
  local port=${1:-5000}
  
  log "INFO" "Uruchamianie kontenera llm-orchestrator-min na porcie $port..."
  
  # Zatrzymanie istniejącego kontenera jeśli istnieje
  docker rm -f llm-orchestrator-min 2>/dev/null || true
  
  # Utworzenie wolumenu dla modeli jeśli nie istnieje
  docker volume create coboarding-models-cache &>/dev/null || true
  
  # Uruchomienie kontenera z wolumenem dla modeli
  docker run -d \
    --name llm-orchestrator-min \
    -p $port:5000 \
    -e API_PORT=5000 \
    -e USE_INT8=true \
    -v coboarding-models-cache:/app/models \
    llm-orchestrator-min:latest
  
  log "INFO" "Kontener uruchomiony, czekam na inicjalizację API..."
  
  # Czekanie na uruchomienie API
  local max_attempts=30
  local attempt=0
  
  while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt+1))
    
    if curl -s http://localhost:$port/api/health &>/dev/null; then
      log "INFO" "API jest dostępne pod adresem: http://localhost:$port"
      log "INFO" "Możesz przetestować API używając: curl -X POST -H 'Content-Type: application/json' -d '{\"prompt\":\"Hello\",\"max_length\":50}' http://localhost:$port/api/generate"
      return 0
    fi
    
    echo -n "."
    sleep 1
  done
  
  log "ERROR" "API nie uruchomiło się w oczekiwanym czasie"
  log "INFO" "Sprawdź logi kontenera: docker logs llm-orchestrator-min"
  return 1
}

# Funkcja do diagnostyki kontenera
diagnose_container() {
  log "INFO" "Diagnostyka kontenera llm-orchestrator-min..."
  
  # Sprawdzenie czy kontener istnieje
  if ! docker ps -a | grep -q llm-orchestrator-min; then
    log "ERROR" "Kontener llm-orchestrator-min nie istnieje"
    return 1
  fi
  
  # Sprawdzenie czy kontener działa
  if ! docker ps | grep -q llm-orchestrator-min; then
    log "WARN" "Kontener llm-orchestrator-min nie jest uruchomiony"
    
    # Sprawdzenie logów
    log "INFO" "Ostatnie logi kontenera:"
    docker logs --tail 20 llm-orchestrator-min
    
    # Próba uruchomienia
    log "INFO" "Próba uruchomienia kontenera..."
    docker start llm-orchestrator-min
    sleep 5
    
    if docker ps | grep -q llm-orchestrator-min; then
      log "INFO" "Kontener został uruchomiony"
    else
      log "ERROR" "Nie udało się uruchomić kontenera"
      return 1
    fi
  fi
  
  # Uruchomienie skryptu diagnostycznego w kontenerze
  log "INFO" "Uruchamianie diagnostyki wewnątrz kontenera..."
  docker exec llm-orchestrator-min /app/scripts/diagnose_api.sh || {
    log "WARN" "Nie można uruchomić skryptu diagnostycznego w kontenerze"
    log "INFO" "Kopiuję skrypt diagnostyczny do kontenera..."
    docker cp /home/tom/github/coboarding/python/containers/llm-orchestrator-min/scripts/diagnose_api.sh llm-orchestrator-min:/app/scripts/
    docker exec llm-orchestrator-min chmod +x /app/scripts/diagnose_api.sh
    docker exec llm-orchestrator-min /app/scripts/diagnose_api.sh
  }
  
  return 0
}

# Funkcja do naprawy kontenera
fix_container() {
  log "INFO" "Naprawa kontenera llm-orchestrator-min..."
  
  # Sprawdzenie czy kontener istnieje
  if ! docker ps -a | grep -q llm-orchestrator-min; then
    log "ERROR" "Kontener llm-orchestrator-min nie istnieje, najpierw go zbuduj i uruchom"
    return 1
  fi
  
  # Uruchomienie skryptu naprawczego w kontenerze
  log "INFO" "Uruchamianie skryptu naprawczego wewnątrz kontenera..."
  docker exec llm-orchestrator-min /app/scripts/fix_common_issues.sh || {
    log "WARN" "Nie można uruchomić skryptu naprawczego w kontenerze"
    log "INFO" "Kopiuję skrypt naprawczy do kontenera..."
    docker cp /home/tom/github/coboarding/python/containers/llm-orchestrator-min/scripts/fix_common_issues.sh llm-orchestrator-min:/app/scripts/
    docker exec llm-orchestrator-min chmod +x /app/scripts/fix_common_issues.sh
    docker exec llm-orchestrator-min /app/scripts/fix_common_issues.sh
  }
  
  # Restart kontenera
  log "INFO" "Restart kontenera..."
  docker restart llm-orchestrator-min
  
  # Czekanie na uruchomienie API
  log "INFO" "Czekam na uruchomienie API..."
  local max_attempts=30
  local attempt=0
  
  while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt+1))
    
    if curl -s http://localhost:5000/api/health &>/dev/null; then
      log "INFO" "API jest dostępne pod adresem: http://localhost:5000"
      return 0
    fi
    
    echo -n "."
    sleep 1
  done
  
  log "ERROR" "API nie uruchomiło się po naprawie"
  return 1
}

# Funkcja do testowania API
test_api() {
  log "INFO" "Testowanie API llm-orchestrator-min..."
  
  # Sprawdzenie czy kontener działa
  if ! docker ps | grep -q llm-orchestrator-min; then
    log "ERROR" "Kontener llm-orchestrator-min nie jest uruchomiony"
    return 1
  fi
  
  # Uruchomienie skryptu testowego w kontenerze
  log "INFO" "Uruchamianie testów API..."
  docker exec llm-orchestrator-min /app/scripts/test_api.sh || {
    log "WARN" "Nie można uruchomić skryptu testowego w kontenerze"
    log "INFO" "Kopiuję skrypt testowy do kontenera..."
    docker cp /home/tom/github/coboarding/python/containers/llm-orchestrator-min/scripts/test_api.sh llm-orchestrator-min:/app/scripts/
    docker exec llm-orchestrator-min chmod +x /app/scripts/test_api.sh
    docker exec llm-orchestrator-min /app/scripts/test_api.sh
  }
  
  return 0
}

# Funkcja do zarządzania cache
manage_cache() {
  log "INFO" "Zarządzanie cache Docker..."
  
  # Uruchomienie skryptu zarządzania cache
  /home/tom/github/coboarding/python/containers/llm-orchestrator-min/scripts/manage_cache.sh "$1"
  
  return 0
}

# Funkcja pomocy
show_help() {
  echo -e "${BLUE}=== Zarządzanie kontenerem llm-orchestrator-min ===${NC}"
  echo ""
  echo "Użycie: $0 [opcja]"
  echo ""
  echo "Opcje:"
  echo "  build      - Buduje kontener z optymalizacjami cache"
  echo "  run [port] - Uruchamia kontener (domyślny port: 5000)"
  echo "  diagnose   - Diagnostyka kontenera i API"
  echo "  fix        - Naprawa typowych problemów"
  echo "  test       - Testowanie API"
  echo "  cache      - Zarządzanie cache Docker"
  echo "  help       - Wyświetla tę pomoc"
  echo ""
  echo "Przykłady:"
  echo "  $0 build           # Buduje kontener"
  echo "  $0 run 5001        # Uruchamia kontener na porcie 5001"
  echo "  $0 diagnose        # Diagnostyka kontenera"
  echo ""
}

# Główna logika skryptu
case "$1" in
  build)
    build_container
    ;;
  run)
    run_container "$2"
    ;;
  diagnose)
    diagnose_container
    ;;
  fix)
    fix_container
    ;;
  test)
    test_api
    ;;
  cache)
    manage_cache "$2"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    show_help
    ;;
esac

exit 0
