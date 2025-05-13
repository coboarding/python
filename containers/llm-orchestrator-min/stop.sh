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

# Funkcja do sprawdzania błędów
check_error() {
    if [ $? -ne 0 ]; then
        log_warn "$1"
        # Nie przerywamy wykonania skryptu w przypadku błędu, aby spróbować zatrzymać wszystkie kontenery
    fi
}

# Funkcja do sprawdzania, czy docker-compose jest zainstalowany
check_docker_compose() {
    log_info "Sprawdzanie, czy docker-compose jest zainstalowany..."
    if ! command -v docker-compose &> /dev/null; then
        log_warn "docker-compose nie jest zainstalowany. Użyję polecenia 'docker compose'."
        DOCKER_COMPOSE="docker compose"
    else
        DOCKER_COMPOSE="docker-compose"
    fi
    
    log_info "Używam polecenia: $DOCKER_COMPOSE"
}

# Funkcja do zatrzymania mikrousług
stop_microservices() {
    log_info "Zatrzymywanie mikrousług..."
    
    if [ -f "docker-compose.yml" ]; then
        $DOCKER_COMPOSE down
        check_error "Zatrzymanie mikrousług nie powiodło się w pełni."
    else
        log_warn "Plik docker-compose.yml nie istnieje. Zatrzymywanie kontenerów ręcznie..."
        
        # Zatrzymanie kontenerów mikrousług
        for container in llm-model-service llm-api-gateway; do
            if docker ps -a | grep -q "$container"; then
                log_info "Zatrzymywanie kontenera $container..."
                docker stop $container
                docker rm $container
                check_error "Zatrzymanie kontenera $container nie powiodło się."
            fi
        done
    fi
    
    log_info "Mikrousługi zostały zatrzymane."
}

# Funkcja do zatrzymania środowiska testowego
stop_test_environment() {
    log_info "Zatrzymywanie środowiska testowego..."
    
    # Zatrzymanie kontenerów testowych
    for container in browser novnc; do
        if docker ps -a | grep -q "$container"; then
            log_info "Zatrzymywanie kontenera $container..."
            docker stop $container
            docker rm $container
            check_error "Zatrzymanie kontenera $container nie powiodło się."
        fi
    done
    
    log_info "Środowisko testowe zostało zatrzymane."
}

# Funkcja do usuwania sieci Docker
remove_network() {
    log_info "Usuwanie sieci Docker 'llm-network'..."
    
    if docker network ls | grep -q "llm-network"; then
        # Sprawdzenie, czy jakieś kontenery są podłączone do sieci
        if docker network inspect llm-network | grep -q "Containers"; then
            log_warn "Kontenery są nadal podłączone do sieci 'llm-network'. Odłączanie..."
            
            # Pobieranie listy kontenerów podłączonych do sieci
            CONTAINERS=$(docker network inspect llm-network -f '{{range $k, $v := .Containers}}{{$k}} {{end}}')
            
            # Odłączanie kontenerów od sieci
            for container in $CONTAINERS; do
                log_info "Odłączanie kontenera $container od sieci 'llm-network'..."
                docker network disconnect -f llm-network $container
                check_error "Odłączenie kontenera $container nie powiodło się."
            done
        fi
        
        # Usuwanie sieci
        docker network rm llm-network
        check_error "Usunięcie sieci 'llm-network' nie powiodło się."
    else
        log_info "Sieć 'llm-network' nie istnieje."
    fi
}

# Funkcja do usuwania wolumenów Docker
remove_volumes() {
    log_info "Sprawdzanie wolumenów Docker..."
    
    # Sprawdzanie, czy istnieją wolumeny nazwane
    if docker volume ls | grep -q -E "(model-data|package-cache|model-cache)"; then
        log_info "Znaleziono wolumeny Docker. Czy chcesz je usunąć? (y/n)"
        read -r answer
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            log_info "Usuwanie wolumenów Docker..."
            
            # Usuwanie wolumenów związanych z mikrousługami
            for volume in model-data package-cache model-cache; do
                if docker volume ls | grep -q "$volume"; then
                    log_info "Usuwanie wolumenu $volume..."
                    docker volume rm $volume
                    check_error "Usunięcie wolumenu $volume nie powiodło się."
                fi
            done
            
            log_info "Wolumeny zostały usunięte."
        else
            log_info "Wolumeny pozostają nienaruszony."
        fi
    else
        log_info "Nie znaleziono wolumenów Docker do usunięcia."
    fi
}

# Funkcja do czyszczenia plików tymczasowych
clean_temp_files() {
    log_info "Czyszczenie plików tymczasowych..."
    
    # Usuwanie katalogu test_files
    if [ -d "./test_files" ]; then
        log_info "Usuwanie katalogu test_files..."
        rm -rf ./test_files
        check_error "Usunięcie katalogu test_files nie powiodło się."
    fi
    
    log_info "Pliki tymczasowe zostały wyczyszczone."
}

# Funkcja do pytania użytkownika o usunięcie cache
ask_remove_cache() {
    log_info "Czy chcesz usunąć katalog cache? (y/n)"
    read -r answer
    
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        log_info "Usuwanie katalogu cache..."
        
        if [ -d "./.cache" ]; then
            rm -rf ./.cache
            check_error "Usunięcie katalogu cache nie powiodło się."
        fi
        
        log_info "Katalog cache został usunięty."
    else
        log_info "Katalog cache pozostaje nienaruszony."
    fi
}

# Główna funkcja
main() {
    log_info "Zatrzymywanie systemu LLM..."
    
    # Sprawdzenie, czy docker-compose jest zainstalowany
    check_docker_compose
    
    # Zatrzymanie mikrousług
    stop_microservices
    
    # Zatrzymanie środowiska testowego
    stop_test_environment
    
    # Usuwanie sieci Docker
    remove_network
    
    # Usuwanie wolumenów Docker
    remove_volumes
    
    # Czyszczenie plików tymczasowych
    clean_temp_files
    
    # Pytanie o usunięcie cache
    ask_remove_cache
    
    log_info "System został zatrzymany pomyślnie."
}

# Uruchomienie głównej funkcji
main
