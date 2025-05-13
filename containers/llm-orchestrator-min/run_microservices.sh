#!/bin/bash
# Skrypt do uruchamiania architektury mikrousług llm-orchestrator-min

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Funkcja do sprawdzania wymagań
check_requirements() {
    log_info "Sprawdzanie wymagań..."
    
    # Sprawdzenie Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker nie jest zainstalowany. Zainstaluj Docker i spróbuj ponownie."
        exit 1
    fi
    
    # Sprawdzenie Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_warn "Docker Compose nie jest zainstalowany. Próba instalacji..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        if ! command -v docker-compose &> /dev/null; then
            log_error "Nie udało się zainstalować Docker Compose. Zainstaluj ręcznie i spróbuj ponownie."
            exit 1
        fi
    fi
    
    log_info "Wszystkie wymagania spełnione."
}

# Funkcja do budowania mikrousług
build_services() {
    log_info "Budowanie mikrousług..."
    
    # Parametr --no-cache jest opcjonalny
    if [ "$1" == "--no-cache" ]; then
        log_info "Budowanie bez użycia cache..."
        docker-compose build --no-cache
    else
        docker-compose build
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Błąd podczas budowania mikrousług."
        exit 1
    fi
    
    log_info "Mikrousługi zbudowane pomyślnie."
}

# Funkcja do uruchamiania mikrousług
run_services() {
    log_info "Uruchamianie mikrousług..."
    
    # Sprawdzenie, czy port jest już używany
    if netstat -tuln | grep -q ":80 "; then
        log_warn "Port 80 jest już używany. Zmieniam port na 8000..."
        export API_PORT=8000
    fi
    
    # Uruchomienie usług w tle
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Błąd podczas uruchamiania mikrousług."
        exit 1
    fi
    
    log_info "Mikrousługi uruchomione pomyślnie."
    
    # Wyświetlenie informacji o dostępie
    if [ -n "$API_PORT" ]; then
        log_info "API dostępne pod adresem: http://localhost:$API_PORT/api"
        log_info "Dashboard Traefik dostępny pod adresem: http://localhost:8080"
    else
        log_info "API dostępne pod adresem: http://localhost:80/api"
        log_info "Dashboard Traefik dostępny pod adresem: http://localhost:8080"
    fi
}

# Funkcja do zatrzymywania mikrousług
stop_services() {
    log_info "Zatrzymywanie mikrousług..."
    
    docker-compose down
    
    if [ $? -ne 0 ]; then
        log_error "Błąd podczas zatrzymywania mikrousług."
        exit 1
    fi
    
    log_info "Mikrousługi zatrzymane pomyślnie."
}

# Funkcja do wyświetlania logów
show_logs() {
    if [ -z "$1" ]; then
        log_info "Wyświetlanie logów wszystkich usług..."
        docker-compose logs -f
    else
        log_info "Wyświetlanie logów usługi $1..."
        docker-compose logs -f $1
    fi
}

# Funkcja do uruchamiania testów
run_tests() {
    log_info "Uruchamianie testów..."
    
    # Sprawdzenie, czy API jest dostępne
    API_URL="http://localhost"
    if [ -n "$API_PORT" ]; then
        API_URL="$API_URL:$API_PORT"
    fi
    
    # Czekanie na dostępność API
    log_info "Czekam na dostępność API pod adresem: $API_URL/api/health"
    for i in {1..60}; do
        if curl -s "$API_URL/api/health" > /dev/null; then
            break
        fi
        echo -n "."
        sleep 1
        
        if [ $i -eq 60 ]; then
            log_error "API nie uruchomiło się w oczekiwanym czasie."
            exit 1
        fi
    done
    
    echo ""
    log_info "API jest dostępne. Uruchamiam testy..."
    
    # Uruchomienie skryptu testowego
    ./microservices/model-service/scripts/run_tests_after_startup.sh --url=$API_URL
    
    if [ $? -ne 0 ]; then
        log_error "Testy zakończyły się niepowodzeniem."
        exit 1
    fi
    
    log_info "Testy zakończone pomyślnie."
}

# Funkcja do wyświetlania pomocy
show_help() {
    echo "Użycie: $0 [opcja] [argumenty]"
    echo ""
    echo "Opcje:"
    echo "  build [--no-cache]    Budowanie mikrousług"
    echo "  run                   Uruchomienie mikrousług"
    echo "  stop                  Zatrzymanie mikrousług"
    echo "  logs [usługa]         Wyświetlanie logów (opcjonalnie dla konkretnej usługi)"
    echo "  test                  Uruchomienie testów"
    echo "  help                  Wyświetlenie tej pomocy"
    echo ""
    echo "Przykłady:"
    echo "  $0 build              Budowanie mikrousług"
    echo "  $0 build --no-cache   Budowanie mikrousług bez użycia cache"
    echo "  $0 run                Uruchomienie mikrousług"
    echo "  $0 logs model-service Wyświetlanie logów usługi model-service"
}

# Główna logika skryptu
case "$1" in
    build)
        check_requirements
        build_services $2
        ;;
    run)
        check_requirements
        run_services
        ;;
    stop)
        stop_services
        ;;
    logs)
        show_logs $2
        ;;
    test)
        run_tests
        ;;
    help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
