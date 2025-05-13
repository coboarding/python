#!/bin/bash
# tests.sh - uruchamia wszystkie testy jednostkowe i integracyjne w projekcie coboarding
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[coBoarding]${NC} $1"
}
err() {
  echo -e "${RED}[coBoarding]${NC} $1" >&2
}

log "Aktywacja środowiska wirtualnego..."
if [ -d "venv-py3.12" ]; then
  source venv-py3.12/bin/activate
elif [ -d "venv-py3.11" ]; then
  source venv-py3.11/bin/activate
elif [ -d "venv" ]; then
  source venv/bin/activate
else
  err "Brak środowiska wirtualnego! Uruchom najpierw install.sh."
  exit 1
fi

log "Wyszukiwanie i uruchamianie testów Python (pytest)..."
if command -v pytest &>/dev/null; then
  pytest || err "Niektóre testy pytest nie przeszły!"
else
  log "pytest nie jest zainstalowany. Instaluję..."
  pip install pytest && pytest || err "Niektóre testy pytest nie przeszły!"
fi

log "Wyszukiwanie i uruchamianie testów shell (test_*.sh)..."
find . -type f -name 'test_*.sh' -exec bash {} \;

log "Wszystkie testy zakończone."
