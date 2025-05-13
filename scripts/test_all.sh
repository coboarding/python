#!/bin/bash

# Kolory do formatowania wyjścia
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Test wszystkich komponentów coBoarding Minimal ===${NC}"

# Nadanie uprawnień wykonywania dla skryptów testowych
chmod +x ./scripts/test_llm_orchestrator.sh
chmod +x ./scripts/test_browser_service.sh
chmod +x ./scripts/test_novnc.sh

# Test llm-orchestrator-min
echo -e "${YELLOW}Uruchamianie testu llm-orchestrator-min...${NC}"
./scripts/test_llm_orchestrator.sh
LLM_RESULT=$?

# Test browser-service
echo -e "${YELLOW}Uruchamianie testu browser-service...${NC}"
./scripts/test_browser_service.sh
BROWSER_RESULT=$?

# Test novnc
echo -e "${YELLOW}Uruchamianie testu novnc...${NC}"
./scripts/test_novnc.sh
NOVNC_RESULT=$?

# Podsumowanie testów
echo -e "${YELLOW}=== Podsumowanie testów ===${NC}"
if [ $LLM_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Test llm-orchestrator-min: SUKCES${NC}"
else
    echo -e "${RED}✗ Test llm-orchestrator-min: BŁĄD${NC}"
fi

if [ $BROWSER_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Test browser-service: SUKCES${NC}"
else
    echo -e "${RED}✗ Test browser-service: BŁĄD${NC}"
fi

if [ $NOVNC_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Test novnc: SUKCES${NC}"
else
    echo -e "${RED}✗ Test novnc: BŁĄD${NC}"
fi

# Wynik końcowy
if [ $LLM_RESULT -eq 0 ] && [ $BROWSER_RESULT -eq 0 ] && [ $NOVNC_RESULT -eq 0 ]; then
    echo -e "${GREEN}=== Wszystkie testy zakończone pomyślnie ===${NC}"
    exit 0
else
    echo -e "${RED}=== Niektóre testy zakończone niepowodzeniem ===${NC}"
    exit 1
fi
