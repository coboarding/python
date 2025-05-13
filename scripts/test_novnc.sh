#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Test kontenera novnc ===${NC}"

# Sprawdzenie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker nie jest zainstalowany. Test niemożliwy.${NC}"
    exit 1
fi

# Budowanie kontenera
echo -e "${YELLOW}Budowanie kontenera novnc...${NC}"
docker build -t novnc:test ./containers/novnc

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas budowania kontenera novnc.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener novnc zbudowany pomyślnie.${NC}"
fi

# Uruchomienie kontenera
echo -e "${YELLOW}Uruchamianie kontenera novnc...${NC}"
CONTAINER_ID=$(docker run -d --name novnc-test -p 8080:8080 novnc:test)

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas uruchamiania kontenera novnc.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener novnc uruchomiony pomyślnie.${NC}"
fi

# Sprawdzenie czy noVNC jest dostępny
echo -e "${YELLOW}Sprawdzanie czy noVNC jest dostępny...${NC}"
sleep 5
if curl -s http://localhost:8080 | grep -q "noVNC"; then
    echo -e "${GREEN}noVNC jest dostępny na porcie 8080.${NC}"
    NOVNC_READY=true
else
    echo -e "${RED}noVNC nie jest dostępny na porcie 8080.${NC}"
    NOVNC_READY=false
fi

# Sprawdzenie logów kontenera
echo -e "${YELLOW}Sprawdzanie logów kontenera...${NC}"
LOGS=$(docker logs novnc-test)
if [[ $LOGS == *"error"* || $LOGS == *"Error"* || $LOGS == *"ERROR"* ]]; then
    echo -e "${RED}Znaleziono błędy w logach kontenera:${NC}"
    echo "$LOGS" | grep -i "error"
else
    echo -e "${GREEN}Nie znaleziono błędów w logach kontenera.${NC}"
fi

# Zatrzymanie i usunięcie kontenera
echo -e "${YELLOW}Zatrzymywanie i usuwanie kontenera testowego...${NC}"
docker stop novnc-test
docker rm novnc-test

if [ "$NOVNC_READY" = true ]; then
    echo -e "${GREEN}Test kontenera novnc zakończony pomyślnie.${NC}"
    exit 0
else
    echo -e "${RED}Test kontenera novnc zakończony niepowodzeniem.${NC}"
    exit 1
fi
