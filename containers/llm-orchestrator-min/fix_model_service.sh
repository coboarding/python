#!/bin/bash

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Sprawdzenie, czy katalog models istnieje
if [ ! -d "./models" ]; then
    log_info "Tworzenie katalogu models..."
    mkdir -p ./models
fi

# Sprawdzenie, czy katalog models/tinyllama istnieje
if [ ! -d "./models/tinyllama" ]; then
    log_info "Tworzenie katalogu models/tinyllama..."
    mkdir -p ./models/tinyllama
fi

# Funkcja do naprawy kontenera model-service
fix_model_service() {
    log_info "Naprawianie kontenera model-service..."
    
    # Zatrzymanie kontenera model-service
    log_info "Zatrzymywanie kontenera model-service..."
    docker stop llm-model-service 2>/dev/null || true
    docker rm llm-model-service 2>/dev/null || true
    
    # Pobieranie modelu za pomocą skryptu Docker
    if [ ! -f "./models/tinyllama/pytorch_model.bin" ] || [ $(stat -c%s "./models/tinyllama/pytorch_model.bin") -lt 1000000 ]; then
        log_info "Model nie jest poprawnie pobrany. Pobieranie modelu..."
        
        # Nadanie uprawnień wykonywania dla skryptu
        chmod +x download_model_docker.sh
        
        # Uruchomienie skryptu pobierania modelu
        ./download_model_docker.sh
        
        if [ $? -ne 0 ]; then
            log_error "Błąd podczas pobierania modelu."
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
    
    # Uruchomienie kontenera model-service
    log_info "Uruchamianie kontenera model-service..."
    docker run -d \
        --name llm-model-service \
        --network llm-network \
        -v "$(pwd)/models:/app/models" \
        -e MODEL_PATH=/app/models/tinyllama \
        -e USE_INT8=true \
        -e MODEL_SERVICE_PORT=5000 \
        llm-model-service
    
    # Sprawdzenie, czy kontener został uruchomiony
    if docker ps | grep -q "llm-model-service"; then
        log_info "Kontener model-service został uruchomiony pomyślnie."
    else
        log_error "Błąd podczas uruchamiania kontenera model-service."
        log_info "Sprawdzanie logów kontenera..."
        docker logs llm-model-service
        exit 1
    fi
    
    log_info "Oczekiwanie na uruchomienie modelu (może to potrwać kilka minut)..."
    log_info "Możesz monitorować postęp ładowania modelu za pomocą: ./monitor.sh --model --live"
}

# Główna funkcja
main() {
    log_info "Rozpoczynanie naprawy modelu..."
    
    # Sprawdzenie, czy Docker jest zainstalowany
    if ! command -v docker &> /dev/null; then
        log_error "Docker nie jest zainstalowany. Zainstaluj Docker i spróbuj ponownie."
        exit 1
    fi
    
    # Sprawdzenie, czy sieć llm-network istnieje
    if ! docker network ls | grep -q "llm-network"; then
        log_info "Tworzenie sieci llm-network..."
        docker network create llm-network
    fi
    
    # Naprawianie kontenera model-service
    fix_model_service
    
    log_info "Naprawa zakończona pomyślnie."
    log_info "Aby monitorować status modelu, użyj: ./monitor.sh --model --live"
    log_info "Pełny status systemu: ./monitor.sh"
}

# Uruchomienie głównej funkcji
main "$@"
