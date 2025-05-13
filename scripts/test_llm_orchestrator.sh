#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Test kontenera llm-orchestrator-min ===${NC}"

# Sprawdzenie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker nie jest zainstalowany. Test niemożliwy.${NC}"
    exit 1
fi

# Tworzenie katalogów dla wolumenów
mkdir -p ./volumes/models ./volumes/config

# Sprawdzenie czy wolumen pip-cache istnieje
if ! docker volume inspect coboarding-pip-cache &>/dev/null; then
    echo -e "${YELLOW}Tworzenie wolumenu pip-cache...${NC}"
    docker volume create coboarding-pip-cache
fi

# Budowanie kontenera
echo -e "${YELLOW}Budowanie kontenera llm-orchestrator-min...${NC}"
docker build -t llm-orchestrator-min:test ./containers/llm-orchestrator-min

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas budowania kontenera llm-orchestrator-min.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener llm-orchestrator-min zbudowany pomyślnie.${NC}"
fi

# Uruchomienie kontenera
echo -e "${YELLOW}Uruchamianie kontenera llm-orchestrator-min...${NC}"
CONTAINER_ID=$(docker run -d --name llm-test -p 5000:5000 \
    -v $(pwd)/volumes/models:/app/models \
    -v $(pwd)/volumes/config:/app/config \
    -v coboarding-pip-cache:/root/.cache/pip \
    -e USE_INT8=true \
    -e PYTHONUNBUFFERED=1 \
    llm-orchestrator-min:test)

if [ $? -ne 0 ]; then
    echo -e "${RED}Błąd podczas uruchamiania kontenera llm-orchestrator-min.${NC}"
    exit 1
else
    echo -e "${GREEN}Kontener llm-orchestrator-min uruchomiony pomyślnie.${NC}"
fi

# Czekanie na uruchomienie API
echo -e "${YELLOW}Czekanie na uruchomienie API...${NC}"
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
    echo -e "${GREEN}API LLM jest gotowe!${NC}"
    
    # Test generowania tekstu
    echo -e "${YELLOW}Testowanie generowania tekstu...${NC}"
    RESPONSE=$(curl -s -X POST http://localhost:5000/api/generate \
        -H "Content-Type: application/json" \
        -d '{"prompt": "Hello, how are you?", "max_length": 50}')
    
    if [[ $RESPONSE == *"response"* && $RESPONSE == *"success"* ]]; then
        echo -e "${GREEN}Test generowania tekstu zakończony pomyślnie.${NC}"
        echo -e "Odpowiedź: $(echo $RESPONSE | grep -o '"response":"[^"]*"' | cut -d'"' -f4)"
    else
        echo -e "${RED}Test generowania tekstu zakończony niepowodzeniem.${NC}"
        echo -e "Odpowiedź: $RESPONSE"
    fi
else
    echo -e "${RED}API LLM nie jest gotowe po czasie oczekiwania.${NC}"
fi

# Zatrzymanie i usunięcie kontenera
echo -e "${YELLOW}Zatrzymywanie i usuwanie kontenera testowego...${NC}"
docker stop llm-test
docker rm llm-test

if [ "$API_READY" = true ]; then
    echo -e "${GREEN}Test kontenera llm-orchestrator-min zakończony pomyślnie.${NC}"
    exit 0
else
    echo -e "${RED}Test kontenera llm-orchestrator-min zakończony niepowodzeniem.${NC}"
    exit 1
fi
