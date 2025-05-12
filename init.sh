#!/bin/bash
# init.sh - skrypt inicjalizacyjny systemu

# Kolory do komunikatów
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}   Inicjalizacja AutoFormFiller Pro  ${NC}"
echo -e "${BLUE}======================================${NC}"

# Utworzenie struktury katalogów
mkdir -p volumes/{cv,models,config,passwords,recordings}

# Sprawdzenie dostępności GPU
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}Wykryto GPU NVIDIA. System będzie używał akceleracji GPU.${NC}"
    USE_GPU=true
else
    echo -e "${YELLOW}Nie wykryto GPU NVIDIA. System będzie działał na CPU.${NC}"
    USE_GPU=false
fi

# Podpowiedź o umieszczeniu CV
echo -e "${YELLOW}Pamiętaj, aby umieścić swoje CV w katalogu 'volumes/cv/'${NC}"

# Pobieranie modeli LLM jeśli nie istnieją
if [ ! -f "volumes/models/phi-2-q4.gguf" ]; then
    echo -e "${GREEN}Pobieranie modelu podstawowego (Phi-2)...${NC}"
    curl -L -o volumes/models/phi-2-q4.gguf https://huggingface.co/TheBloke/Phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf
fi

# Uruchomienie systemu
echo -e "${GREEN}Uruchamianie systemu AutoFormFiller Pro...${NC}"
docker-compose up -d

# Informacja o dostępie
echo -e "${GREEN}System został uruchomiony!${NC}"
echo -e "${YELLOW}Terminal webowy dostępny pod adresem:${NC} http://localhost:8081"
echo -e "${YELLOW}Podgląd przeglądarki dostępny pod adresem:${NC} http://localhost:8080"

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}  AutoFormFiller Pro gotowy do użycia ${NC}"
echo -e "${BLUE}======================================${NC}"