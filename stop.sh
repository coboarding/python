#!/bin/bash
# stop.sh - zatrzymuje usługi i usuwa wszystkie kontenery oraz sieci dockera powiązane z projektem coboarding
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[coBoarding]${NC} $1"
}
warn() {
  echo -e "${YELLOW}[coBoarding]${NC} $1"
}
err() {
  echo -e "${RED}[coBoarding]${NC} $1" >&2
}

log "Zatrzymywanie wszystkich środowisk testowych docker-compose.<service>.yml..."
SERVICES=(llm-orchestrator browser-service web-interface novnc video-chat web-terminal)
for SERVICE in "${SERVICES[@]}"; do
  COMPOSE_FILE="docker-compose.$SERVICE.yml"
  if [ -f "$COMPOSE_FILE" ]; then
    log "Zatrzymuję środowisko dla: $SERVICE ($COMPOSE_FILE) ..."
    docker-compose -f "$COMPOSE_FILE" down || warn "Nie udało się zatrzymać środowiska $SERVICE."
  fi
done

log "Zatrzymywanie wszystkich usług docker-compose..."
docker compose down || docker-compose down || warn "docker-compose down nie powiodło się (brak pliku lub usługi)"

log "Usuwanie wszystkich kontenerów dockera powiązanych z projektem..."
PROJECT_CONTAINERS=$(docker ps -a --filter "name=coboarding" --format "{{.ID}}")
if [ -n "$PROJECT_CONTAINERS" ]; then
  docker rm -f $PROJECT_CONTAINERS || warn "Nie udało się usunąć niektórych kontenerów."
else
  warn "Brak kontenerów powiązanych z projektem coboarding."
fi

log "Usuwanie nieużywanych sieci docker..."
docker network prune -f || warn "Nie udało się wyczyścić sieci docker."

log "Wszystkie usługi zatrzymane i kontenery usunięte."
