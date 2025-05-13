#!/bin/bash

# Kolory do logów
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Funkcje do logowania
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Sprawdzenie, czy katalog models/tinyllama istnieje
if [ ! -d "./models/tinyllama" ]; then
    log_info "Tworzenie katalogu models/tinyllama..."
    mkdir -p ./models/tinyllama
fi

# Funkcja do pobierania modelu za pomocą kontenera Docker
download_model_with_docker() {
    log_info "Pobieranie modelu za pomocą kontenera Docker..."
    
    # Tworzenie tymczasowego pliku Dockerfile
    cat > Dockerfile.model_downloader << EOF
FROM python:3.9-slim

WORKDIR /app

RUN pip install --no-cache-dir transformers torch

COPY download_model.py /app/

CMD ["python", "download_model.py", "TinyLlama/TinyLlama-1.1B-Chat-v1.0", "/models/tinyllama"]
EOF
    
    # Budowanie obrazu Docker
    log_info "Budowanie obrazu Docker do pobierania modelu..."
    docker build -t model-downloader -f Dockerfile.model_downloader .
    
    if [ $? -ne 0 ]; then
        log_error "Błąd podczas budowania obrazu Docker."
        return 1
    fi
    
    # Uruchamianie kontenera do pobierania modelu
    log_info "Uruchamianie kontenera do pobierania modelu..."
    docker run --rm -v "$(pwd)/models:/models" model-downloader
    
    if [ $? -ne 0 ]; then
        log_error "Błąd podczas pobierania modelu."
        return 1
    fi
    
    # Usuwanie tymczasowego pliku Dockerfile
    rm -f Dockerfile.model_downloader
    
    return 0
}

# Główna funkcja
main() {
    log_info "Rozpoczynanie pobierania modelu..."
    
    # Sprawdzenie, czy model jest już poprawnie pobrany
    if [ ! -f "./models/tinyllama/pytorch_model.bin" ] || [ $(stat -c%s "./models/tinyllama/pytorch_model.bin") -lt 1000000 ]; then
        log_info "Model nie jest poprawnie pobrany. Pobieranie modelu..."
        
        # Pobieranie modelu za pomocą kontenera Docker
        download_model_with_docker
        
        if [ $? -ne 0 ]; then
            log_error "Nie udało się pobrać modelu."
            log_info "Spróbuj pobrać model ręcznie i umieść go w katalogu ./models/tinyllama/"
            exit 1
        fi
    else
        log_info "Model jest już poprawnie pobrany."
    fi
    
    # Sprawdzenie, czy wszystkie pliki zostały pobrane
    log_info "Sprawdzanie, czy wszystkie pliki modelu zostały poprawnie pobrane..."
    local all_files_ok=true
    
    for file in config.json generation_config.json tokenizer.json tokenizer_config.json pytorch_model.bin; do
        if [ ! -f "./models/tinyllama/$file" ] || [ $(stat -c%s "./models/tinyllama/$file") -eq 0 ]; then
            log_error "Plik $file nie istnieje lub jest pusty."
            all_files_ok=false
        else
            log_info "Plik $file OK ($(stat -c%s "./models/tinyllama/$file") bajtów)"
        fi
    done
    
    if [ "$all_files_ok" = false ]; then
        log_error "Nie wszystkie pliki modelu zostały poprawnie pobrane. Spróbuj ponownie."
        exit 1
    fi
    
    log_info "Model został pomyślnie pobrany."
}

# Uruchomienie głównej funkcji
main
