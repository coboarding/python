#!/bin/bash
# Skrypt do uruchamiania architektury mikrousług llm-orchestrator-min

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Funkcja do sprawdzania cache
check_cache() {
    log_info "Sprawdzanie cache pakietów..."
    
    CACHE_DIR="./.cache"
    PIP_CACHE="${CACHE_DIR}/pip"
    MODEL_CACHE="${CACHE_DIR}/models/tinyllama"
    
    # Sprawdzenie, czy katalogi cache istnieją
    if [ ! -d "${PIP_CACHE}" ]; then
        log_warn "Katalog cache pip nie istnieje. Tworzenie..."
        mkdir -p "${PIP_CACHE}"
    else
        log_info "Znaleziono cache pip."
    fi
    
    if [ ! -d "${MODEL_CACHE}" ]; then
        log_warn "Katalog cache modelu nie istnieje. Tworzenie..."
        mkdir -p "${MODEL_CACHE}"
    else
        log_info "Znaleziono cache modelu."
        log_info "Pliki w cache modelu:"
        ls -la "${MODEL_CACHE}"
    fi
}

# Główna logika skryptu
case "$1" in
    build)
        log_info "Budowanie mikrousług..."
        check_cache
        docker-compose build
        ;;
    run)
        log_info "Uruchamianie mikrousług..."
        check_cache
        docker-compose up -d
        log_info "API dostępne pod adresem: http://localhost/api"
        ;;
    stop)
        log_info "Zatrzymywanie mikrousług..."
        docker-compose down
        ;;
    logs)
        log_info "Wyświetlanie logów..."
        docker-compose logs -f $2
        ;;
    test)
        log_info "Uruchamianie testów..."
        curl -s http://localhost/api/health
        ;;
    cache-status)
        check_cache
        ;;
    *)
        echo "Użycie: $0 {build|run|stop|logs|test|cache-status}"
        exit 1
        ;;
esac

exit 0
