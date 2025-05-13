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
mkdir -p ./volumes/models ./volumes/config ./volumes/recordings

# Zatrzymanie istniejących kontenerów, jeśli istnieją
echo -e "${YELLOW}Zatrzymywanie istniejących kontenerów, jeśli istnieją...${NC}"
docker-compose -f docker-compose.min.yml down 2>/dev/null

# Budowanie i uruchamianie kontenerów
echo -e "${GREEN}Budowanie i uruchamianie kontenerów...${NC}"
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
sleep 10

# Otwieranie noVNC w przeglądarce
echo -e "${GREEN}Otwieranie noVNC w przeglądarce...${NC}"
open_browser "http://localhost:8080/vnc.html?autoconnect=true&password=secret"

echo -e "${GREEN}=== coBoarding - Minimalna Wersja uruchomiona ===${NC}"
echo -e "noVNC dostępny pod adresem: http://localhost:8080/vnc.html?autoconnect=true&password=secret"
echo -e "API LLM dostępne pod adresem: http://localhost:5000"
echo -e "${YELLOW}Aby zatrzymać, użyj: docker-compose -f docker-compose.min.yml down${NC}"
