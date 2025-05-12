#!/bin/bash
# setup-all.sh

echo "AutoFormFiller - Automatyczne ustawienie wszystkiego"

# Wykryj system operacyjny
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SYSTEM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="mac"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    SYSTEM="windows"
else
    SYSTEM="unknown"
fi

echo "Wykryto system: $SYSTEM"

# Wykryj dostępność GPU
if command -v nvidia-smi &> /dev/null; then
    echo "Wykryto GPU NVIDIA - zostanie użyte do modeli LLM"
    HAS_GPU=true
else
    echo "Nie wykryto GPU - modele będą używać CPU"
    HAS_GPU=false
fi

# Utwórz potrzebne katalogi
mkdir -p volumes/cv volumes/models volumes/config volumes/recordings

# Poproś o podstawowe dane
read -p "Podaj ścieżkę do pliku CV (lub zostaw puste, aby użyć przykładowego): " CV_PATH
if [ -z "$CV_PATH" ]; then
    echo "Używam przykładowego CV"
    cp examples/example_cv.html volumes/cv/
else
    cp "$CV_PATH" volumes/cv/
fi

# Zbuduj i uruchom wszystko jednym poleceniem
echo "Uruchamiam system AutoFormFiller..."
docker-compose up -d

echo "System dostępny pod adresami:"
echo "- Interfejs web: http://localhost:8082"
echo "- Podgląd przeglądarki: http://localhost:8080"
echo "- Web terminal: http://localhost:8081"

echo "Gotowe! Możesz teraz korzystać z AutoFormFiller."