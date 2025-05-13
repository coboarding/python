#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Test kontenera browser-service ===${NC}"

# Sprawdzenie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker nie jest zainstalowany. Test niemożliwy.${NC}"
    exit 1
fi

# Tworzenie katalogów dla wolumenów
mkdir -p ./volumes/recordings

# Sprawdzenie czy wolumen pip-cache istnieje
if ! docker volume inspect coboarding-pip-cache &>/dev/null; then
    echo -e "${YELLOW}Tworzenie wolumenu pip-cache...${NC}"
    docker volume create coboarding-pip-cache
fi

# Budowanie kontenera
echo -e "${YELLOW}Budowanie kontenera browser-service...${NC}"
docker build -t browser-service:test ./containers/browser-service

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas budowania kontenera browser-service.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener browser-service zbudowany pomyślnie.${NC}"
fi

# Uruchomienie kontenera
echo -e "${YELLOW}Uruchamianie kontenera browser-service...${NC}"
CONTAINER_ID=$(docker run -d --name browser-test -p 5900:5900 \
    -v $(pwd)/volumes/recordings:/app/recordings \
    -v coboarding-pip-cache:/root/.cache/pip \
    -e DISPLAY=:99 \
    -e PYTHONUNBUFFERED=1 \
    browser-service:test)

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas uruchamiania kontenera browser-service.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener browser-service uruchomiony pomyślnie.${NC}"
fi

# Sprawdzenie czy VNC jest dostępny
echo -e "${YELLOW}Sprawdzanie czy VNC jest dostępny...${NC}"
sleep 5
if nc -z localhost 5900; then
    echo -e "${GREEN}VNC jest dostępny na porcie 5900.${NC}"
    VNC_READY=true
else
    echo -e "${RED}VNC nie jest dostępny na porcie 5900.${NC}"
    VNC_READY=false
fi

# Sprawdzenie logów kontenera
echo -e "${YELLOW}Sprawdzanie logów kontenera...${NC}"
LOGS=$(docker logs browser-test)
if [[ $LOGS == *"error"* || $LOGS == *"Error"* || $LOGS == *"ERROR"* ]]; then
    echo -e "${RED}Znaleziono błędy w logach kontenera:${NC}"
    echo "$LOGS" | grep -i "error"
else
    echo -e "${GREEN}Nie znaleziono błędów w logach kontenera.${NC}"
fi

# Zatrzymanie i usunięcie kontenera
echo -e "${YELLOW}Zatrzymywanie i usuwanie kontenera testowego...${NC}"
docker stop browser-test
docker rm browser-test

if [ "$VNC_READY" = true ]; then
    echo -e "${GREEN}Test kontenera browser-service zakończony pomyślnie.${NC}"
    exit 0
else
    echo -e "${RED}Test kontenera browser-service zakończony niepowodzeniem.${NC}"
    exit 1
fi
