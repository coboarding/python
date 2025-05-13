#!/bin/bash
# stop.sh - zatrzymuje usługi i usuwa wszystkie kontenery oraz sieci dockera powiązane z projektem coboarding
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

START_TIME=$(date +%s)

log() {
  echo -e "${GREEN}[coBoarding]${NC} $1"
}
warn() {
  echo -e "${YELLOW}[coBoarding]${NC} $1"
}
err() {
  echo -e "${RED}[coBoarding]${NC} $1" >&2
}
info() {
  echo -e "${BLUE}[coBoarding]${NC} $1"
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
  echo -ne "\r${BLUE}[coBoarding]${NC} ${message} ${bar}"
  
  # Jeśli to ostatni krok, dodaj nową linię
  if [ $current -eq $total ]; then
    echo ""
  fi
}

# Funkcja do zapisywania stanu kontenerów przed zatrzymaniem
save_container_state() {
  local state_file="./container_state.log"
  info "Zapisywanie stanu kontenerów przed zatrzymaniem..."
  
  {
    echo "=== Stan kontenerów przed zatrzymaniem ==="
    echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "=== Uruchomione kontenery ==="
    docker ps -a
    echo ""
    
    echo "=== Statystyki kontenerów ==="
    docker stats --no-stream
    echo ""
    
    echo "=== Wolumeny Docker ==="
    docker volume ls | grep "coboarding"
    echo ""
    
    echo "=== Obrazy Docker ==="
    docker images | grep -E 'llm-orchestrator-min|browser-service|novnc'
    echo ""
  } > "$state_file"
  
  log "Stan kontenerów został zapisany w pliku: $state_file"
}

# Funkcja do czyszczenia wolumenów
clean_volumes() {
  info "Czyszczenie wolumenów Docker..."
  
  local volumes=("coboarding-pip-cache" "coboarding-wheel-cache" "coboarding-models-cache" "coboarding-chrome-cache")
  local total=${#volumes[@]}
  local current=0
  
  for volume in "${volumes[@]}"; do
    current=$((current + 1))
    progress_bar $current $total "Usuwanie wolumenów Docker..."
    
    if docker volume inspect "$volume" &>/dev/null; then
      docker volume rm "$volume" &>/dev/null || warn "Nie udało się usunąć wolumenu $volume."
    fi
  done
  
  log "Wolumeny Docker zostały wyczyszczone."
}

# Parsowanie argumentów wiersza poleceń
SAVE_STATE=false
CLEAN_VOLUMES=false
REMOVE_IMAGES=false
FORCE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --save-state)
      SAVE_STATE=true
      info "Włączono zapisywanie stanu kontenerów."
      shift
      ;;
    --clean-volumes)
      CLEAN_VOLUMES=true
      info "Włączono czyszczenie wolumenów."
      shift
      ;;
    --remove-images)
      REMOVE_IMAGES=true
      info "Włączono usuwanie obrazów."
      shift
      ;;
    --force|-f)
      FORCE=true
      info "Włączono tryb wymuszony (force)."
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      info "Włączono tryb szczegółowy (verbose)."
      shift
      ;;
    --help|-h)
      echo "Użycie: ./stop.sh [opcje]"
      echo "Opcje:"
      echo "  --save-state       Zapisuje stan kontenerów przed zatrzymaniem"
      echo "  --clean-volumes    Czyści wolumeny Docker"
      echo "  --remove-images    Usuwa obrazy Docker"
      echo "  --force, -f        Wymusza operacje bez pytania"
      echo "  --verbose, -v      Włącza tryb szczegółowy (verbose)"
      echo "  --help, -h         Wyświetla tę pomoc"
      exit 0
      ;;
    *)
      err "Nieznana opcja: $1"
      echo "Użyj --help, aby wyświetlić dostępne opcje."
      exit 1
      ;;
  esac
done

# Zapisywanie stanu kontenerów przed zatrzymaniem
if [ "$SAVE_STATE" = true ]; then
  save_container_state
fi

info "=== Zatrzymywanie środowiska coBoarding ==="

# Wyświetlanie informacji o aktualnie uruchomionych kontenerach
if [ "$VERBOSE" = true ]; then
  info "Aktualnie uruchomione kontenery:"
  docker ps
  echo ""
fi

log "Zatrzymywanie wszystkich środowisk testowych docker-compose.<service>.yml..."
SERVICES=(llm-orchestrator browser-service web-interface novnc video-chat web-terminal)
TOTAL_SERVICES=${#SERVICES[@]}
CURRENT=0

for SERVICE in "${SERVICES[@]}"; do
  CURRENT=$((CURRENT + 1))
  COMPOSE_FILE="docker-compose.$SERVICE.yml"
  
  if [ -f "$COMPOSE_FILE" ]; then
    if [ "$VERBOSE" = true ]; then
      info "Zatrzymuję środowisko dla: $SERVICE ($COMPOSE_FILE) ..."
      docker-compose -f "$COMPOSE_FILE" down || warn "Nie udało się zatrzymać środowiska $SERVICE."
    else
      progress_bar $CURRENT $TOTAL_SERVICES "Zatrzymywanie środowisk testowych..."
      docker-compose -f "$COMPOSE_FILE" down &>/dev/null || warn "Nie udało się zatrzymać środowiska $SERVICE."
    fi
  fi
done

log "Zatrzymywanie środowiska minimalnego (docker-compose.min.yml)..."
if [ -f "docker-compose.min.yml" ]; then
  if [ "$VERBOSE" = true ]; then
    docker-compose -f docker-compose.min.yml down || warn "Nie udało się zatrzymać środowiska minimalnego."
  else
    docker-compose -f docker-compose.min.yml down &>/dev/null || warn "Nie udało się zatrzymać środowiska minimalnego."
  fi
fi

log "Zatrzymywanie wszystkich usług docker-compose..."
if [ "$VERBOSE" = true ]; then
  docker compose down || docker-compose down || warn "docker-compose down nie powiodło się (brak pliku lub usługi)"
else
  docker compose down &>/dev/null || docker-compose down &>/dev/null || warn "docker-compose down nie powiodło się (brak pliku lub usługi)"
fi

log "Usuwanie wszystkich kontenerów dockera powiązanych z projektem..."
PROJECT_CONTAINERS=$(docker ps -a --filter "name=coboarding" --format "{{.ID}}")
if [ -n "$PROJECT_CONTAINERS" ]; then
  if [ "$VERBOSE" = true ]; then
    docker rm -f $PROJECT_CONTAINERS || warn "Nie udało się usunąć niektórych kontenerów."
  else
    docker rm -f $PROJECT_CONTAINERS &>/dev/null || warn "Nie udało się usunąć niektórych kontenerów."
  fi
else
  warn "Brak kontenerów powiązanych z projektem coboarding."
fi

# Usuwanie kontenerów z wersji minimalnej
MIN_CONTAINERS="llm-orchestrator-min browser-service novnc"
TOTAL_MIN_CONTAINERS=$(echo "$MIN_CONTAINERS" | wc -w)
CURRENT=0

for CONTAINER in $MIN_CONTAINERS; do
  CURRENT=$((CURRENT + 1))
  
  if docker ps -a --filter "name=$CONTAINER" -q | grep -q .; then
    if [ "$VERBOSE" = true ]; then
      info "Usuwanie kontenera $CONTAINER..."
      docker rm -f $CONTAINER || warn "Nie udało się usunąć kontenera $CONTAINER."
    else
      progress_bar $CURRENT $TOTAL_MIN_CONTAINERS "Usuwanie kontenerów minimalnych..."
      docker rm -f $CONTAINER &>/dev/null || warn "Nie udało się usunąć kontenera $CONTAINER."
    fi
  fi
done

log "Usuwanie nieużywanych sieci docker..."
if [ "$VERBOSE" = true ]; then
  docker network prune -f || warn "Nie udało się wyczyścić sieci docker."
else
  docker network prune -f &>/dev/null || warn "Nie udało się wyczyścić sieci docker."
fi

# Czyszczenie wolumenów Docker
if [ "$CLEAN_VOLUMES" = true ]; then
  if [ "$FORCE" = true ]; then
    clean_volumes
  else
    read -p "Czy na pewno chcesz usunąć wszystkie wolumeny Docker? (t/n): " answer
    if [[ "$answer" =~ ^[Tt]$ ]]; then
      clean_volumes
    else
      info "Pomijanie czyszczenia wolumenów Docker."
    fi
  fi
else
  log "Usuwanie nieużywanych wolumenów docker..."
  if [ "$VERBOSE" = true ]; then
    docker volume prune -f || warn "Nie udało się wyczyścić wolumenów docker."
  else
    docker volume prune -f &>/dev/null || warn "Nie udało się wyczyścić wolumenów docker."
  fi
fi

# Usuwanie obrazów Docker
if [ "$REMOVE_IMAGES" = true ]; then
  info "Usuwanie obrazów Docker..."
  
  if [ "$FORCE" = true ]; then
    for image in "llm-orchestrator-min" "browser-service" "novnc"; do
      if docker images | grep -q "$image"; then
        if [ "$VERBOSE" = true ]; then
          info "Usuwanie obrazu $image..."
          docker rmi $image || warn "Nie udało się usunąć obrazu $image."
        else
          docker rmi $image &>/dev/null || warn "Nie udało się usunąć obrazu $image."
        fi
      fi
    done
    log "Obrazy Docker zostały usunięte."
  else
    read -p "Czy na pewno chcesz usunąć wszystkie obrazy Docker? (t/n): " answer
    if [[ "$answer" =~ ^[Tt]$ ]]; then
      for image in "llm-orchestrator-min" "browser-service" "novnc"; do
        if docker images | grep -q "$image"; then
          if [ "$VERBOSE" = true ]; then
            info "Usuwanie obrazu $image..."
            docker rmi $image || warn "Nie udało się usunąć obrazu $image."
          else
            docker rmi $image &>/dev/null || warn "Nie udało się usunąć obrazu $image."
          fi
        fi
      done
      log "Obrazy Docker zostały usunięte."
    else
      info "Pomijanie usuwania obrazów Docker."
    fi
  fi
fi

log "Wszystkie usługi zatrzymane i kontenery usunięte."

# Wyświetlanie czasu wykonania skryptu
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
info "Czas wykonania skryptu: ${EXECUTION_TIME}s"

# Wyświetlanie podsumowania
info "=== Podsumowanie ==="
info "- Wszystkie kontenery zostały zatrzymane i usunięte"
if [ "$CLEAN_VOLUMES" = true ]; then
  info "- Wolumeny Docker zostały wyczyszczone"
fi
if [ "$REMOVE_IMAGES" = true ]; then
  info "- Obrazy Docker zostały usunięte"
fi
if [ "$SAVE_STATE" = true ]; then
  info "- Stan kontenerów został zapisany w pliku: ./container_state.log"
fi
info "Aby uruchomić środowisko ponownie, użyj: ./runmin.sh"
