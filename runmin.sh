#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== coBoarding - Minimalna Wersja ===${NC}"
echo -e "${YELLOW}Uruchamianie minimalnej wersji coBoarding z prostym modelem LLM (TinyLlama-1.1B)${NC}"
echo -e "${YELLOW}Ta wersja zawiera tylko podstawowe funkcje:${NC}"
echo -e "- Prosty model LLM działający na CPU (do 2B parametrów)"
echo -e "- Przeglądarka dostępna przez noVNC"
echo -e "- Brak menedżerów haseł, pipelines i sterowania głosowego"
echo -e "- Zoptymalizowane cacheowanie paczek"
echo -e "- Kwantyzacja int8 dla mniejszego zużycia pamięci"
echo -e "- Limity zasobów dla kontenerów"

# Włączenie BuildKit dla szybszego budowania
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Sprawdzenie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker nie jest zainstalowany. Instaluję Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
fi

# Sprawdzenie czy Docker Compose jest zainstalowany
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose nie jest zainstalowany. Instaluję Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Tworzenie katalogów dla wolumenów
echo -e "${YELLOW}Tworzenie katalogów dla wolumenów...${NC}"
mkdir -p ./volumes/models ./volumes/config ./volumes/recordings

# Sprawdzenie czy wolumen pip-cache istnieje
if ! docker volume inspect coboarding-pip-cache &>/dev/null; then
    echo -e "${YELLOW}Tworzenie wolumenu pip-cache dla optymalizacji cacheowania...${NC}"
    docker volume create coboarding-pip-cache
else
    echo -e "${GREEN}Wolumen pip-cache już istnieje.${NC}"
fi

# Sprawdzenie dostępnej pamięci
MEM_TOTAL=$(free -g | awk '/^Mem:/{print $2}')
echo -e "${YELLOW}Dostępna pamięć: ${MEM_TOTAL}GB${NC}"

if [ "$MEM_TOTAL" -lt 4 ]; then
    echo -e "${RED}Uwaga: Dostępna pamięć poniżej 4GB. Wydajność może być ograniczona.${NC}"
    # Zmniejszamy limity pamięci dla kontenerów
    sed -i 's/memory: 2G/memory: 1G/g' docker-compose.min.yml
    sed -i 's/memory: 1G/memory: 512M/g' docker-compose.min.yml
    sed -i 's/memory: 256M/memory: 128M/g' docker-compose.min.yml
    echo -e "${YELLOW}Limity pamięci zostały automatycznie zmniejszone.${NC}"
fi

# Zatrzymanie istniejących kontenerów, jeśli istnieją
echo -e "${YELLOW}Zatrzymywanie istniejących kontenerów, jeśli istnieją...${NC}"
docker-compose -f docker-compose.min.yml down 2>/dev/null

# Czyszczenie nieużywanych obrazów i wolumenów dla oszczędności miejsca
echo -e "${YELLOW}Czyszczenie nieużywanych zasobów Docker...${NC}"
docker system prune -f --volumes 2>/dev/null

# Budowanie i uruchamianie kontenerów
echo -e "${GREEN}Budowanie i uruchamianie kontenerów...${NC}"
echo -e "${YELLOW}Pierwsze uruchomienie może potrwać dłużej, kolejne będą szybsze dzięki cache.${NC}"
docker-compose -f docker-compose.min.yml up --build -d

# Sprawdzenie statusu kontenerów
echo -e "${YELLOW}Sprawdzanie statusu kontenerów...${NC}"
docker-compose -f docker-compose.min.yml ps

# Funkcja do otwierania przeglądarki
open_browser() {
  local url="$1"
  echo -e "${GREEN}Otwieranie przeglądarki: $url${NC}"

  # Wykrywanie systemu operacyjnego i otwieranie URL w przeglądarce
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$url" &>/dev/null &
    elif command -v gnome-open &>/dev/null; then
      gnome-open "$url" &>/dev/null &
    else
      echo -e "${YELLOW}Nie można automatycznie otworzyć przeglądarki. Otwórz ręcznie URL: $url${NC}"
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url" &>/dev/null &
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    start "" "$url" &>/dev/null &
  else
    echo -e "${YELLOW}Nieobsługiwany system. Otwórz URL ręcznie: $url${NC}"
    return 1
  fi

  # Daj przeglądarce czas na otwarcie
  sleep 3
  return 0
}

# Czekanie na uruchomienie usług
echo -e "${YELLOW}Czekanie na uruchomienie usług...${NC}"
echo -e "${YELLOW}Sprawdzanie statusu API LLM...${NC}"

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

if [ "$API_READY" = true ]; then
  echo -e "\n${GREEN}API LLM jest gotowe!${NC}"
else
  echo -e "\n${YELLOW}Upłynął limit czasu oczekiwania na API LLM. Kontynuowanie mimo to...${NC}"
fi

# Otwieranie noVNC w przeglądarce
echo -e "${GREEN}Otwieranie noVNC w przeglądarce...${NC}"
open_browser "http://localhost:8080/vnc.html?autoconnect=true&password=secret"

echo -e "${GREEN}=== coBoarding - Minimalna Wersja uruchomiona ===${NC}"
echo -e "noVNC dostępny pod adresem: http://localhost:8080/vnc.html?autoconnect=true&password=secret"
echo -e "API LLM dostępne pod adresem: http://localhost:5000"

# Wyświetlanie informacji o zużyciu zasobów
echo -e "${YELLOW}Informacje o zużyciu zasobów:${NC}"
docker stats --no-stream

echo -e "${YELLOW}Aby zatrzymać, użyj: docker-compose -f docker-compose.min.yml down${NC}"
echo -e "${GREEN}Informacja o cache:${NC} Paczki Pythona są przechowywane w wolumenie Docker 'coboarding-pip-cache'"
echo -e "Dzięki temu kolejne uruchomienia będą znacznie szybsze."
echo -e "${GREEN}Optymalizacje:${NC} Kwantyzacja int8, limity pamięci, BuildKit, cacheowanie paczek"
