#!/bin/bash

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_status() { echo -e "${BLUE}[STATUS]${NC} $1"; }
log_model() { echo -e "${PURPLE}[MODEL]${NC} $1"; }
log_api() { echo -e "${CYAN}[API]${NC} $1"; }

# Funkcja do czyszczenia ekranu
clear_screen() {
    clear
}

# Funkcja do sprawdzania, czy kontener istnieje i działa
check_container() {
    local container_name=$1
    
    if ! docker ps -a | grep -q "$container_name"; then
        echo -e "${RED}Kontener $container_name nie istnieje.${NC}"
        return 1
    fi
    
    if ! docker ps | grep -q "$container_name"; then
        echo -e "${YELLOW}Kontener $container_name istnieje, ale nie jest uruchomiony.${NC}"
        return 2
    fi
    
    echo -e "${GREEN}Kontener $container_name działa.${NC}"
    return 0
}

# Funkcja do wyświetlania statystyk kontenera
show_container_stats() {
    local container_name=$1
    
    echo -e "${BOLD}Statystyki kontenera $container_name:${NC}"
    
    # Pobieranie statystyk CPU i pamięci
    local stats=$(docker stats --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" "$container_name")
    local cpu=$(echo "$stats" | awk '{print $1}')
    local mem_usage=$(echo "$stats" | awk '{print $2 " / " $3}')
    local mem_perc=$(echo "$stats" | awk '{print $4}')
    
    echo -e "CPU: $cpu"
    echo -e "Pamięć: $mem_usage ($mem_perc)"
    
    # Pobieranie statusu kontenera
    local status=$(docker inspect --format='{{.State.Status}}' "$container_name")
    local running_for=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" | xargs -I{} date -d {} +%s)
    local now=$(date +%s)
    local uptime=$((now - running_for))
    
    echo -e "Status: $status"
    echo -e "Czas działania: $(printf '%02d:%02d:%02d' $((uptime/3600)) $((uptime%3600/60)) $((uptime%60)))"
    echo
}

# Funkcja do wyświetlania ostatnich logów kontenera
show_container_logs() {
    local container_name=$1
    local lines=$2
    
    echo -e "${BOLD}Ostatnie logi kontenera $container_name:${NC}"
    docker logs --tail "$lines" "$container_name" | grep -v "^$"
    echo
}

# Funkcja do sprawdzania statusu API
check_api_status() {
    echo -e "${BOLD}Status API:${NC}"
    
    # Sprawdzanie, czy API jest dostępne
    local api_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health)
    
    if [ "$api_response" == "200" ]; then
        echo -e "${GREEN}API jest dostępne (HTTP 200)${NC}"
        
        # Pobieranie szczegółowych informacji o API
        local api_details=$(curl -s http://localhost/api/health)
        echo -e "Odpowiedź API: $api_details"
    elif [ "$api_response" == "503" ]; then
        echo -e "${YELLOW}API jest w trakcie uruchamiania (HTTP 503 - Service Unavailable)${NC}"
        echo -e "Model LLM jest prawdopodobnie jeszcze w trakcie ładowania."
    else
        echo -e "${RED}API nie jest dostępne (HTTP $api_response)${NC}"
    fi
    
    echo
}

# Funkcja do sprawdzania postępu ładowania modelu
check_model_loading_progress() {
    echo -e "${BOLD}Postęp ładowania modelu:${NC}"
    
    # Sprawdzanie, czy model jest w trakcie ładowania
    if docker logs llm-model-service 2>&1 | grep -q "Loading model"; then
        echo -e "${YELLOW}Model jest w trakcie ładowania...${NC}"
        
        # Wyświetlanie postępu ładowania modelu
        local loading_logs=$(docker logs llm-model-service 2>&1 | grep -E "Loading model|Loading checkpoint|Loaded model|Model loaded" | tail -5)
        echo "$loading_logs"
        
        # Sprawdzanie, czy model został załadowany
        if docker logs llm-model-service 2>&1 | grep -q "Model loaded successfully"; then
            echo -e "${GREEN}Model został załadowany pomyślnie!${NC}"
        fi
    elif docker logs llm-model-service 2>&1 | grep -q "Model loaded successfully"; then
        echo -e "${GREEN}Model został załadowany pomyślnie!${NC}"
        
        # Wyświetlanie informacji o modelu
        local model_info=$(docker logs llm-model-service 2>&1 | grep -E "Model loaded successfully|Model size|Quantization" | tail -3)
        echo "$model_info"
    else
        echo -e "${YELLOW}Nie można określić statusu ładowania modelu.${NC}"
    fi
    
    echo
}

# Funkcja do sprawdzania ruchu sieciowego
check_network_traffic() {
    echo -e "${BOLD}Ruch sieciowy:${NC}"
    
    # Sprawdzanie, czy sieć llm-network istnieje
    if ! docker network ls | grep -q "llm-network"; then
        echo -e "${RED}Sieć llm-network nie istnieje.${NC}"
        return
    fi
    
    # Wyświetlanie informacji o sieci
    echo -e "Kontenery podłączone do sieci llm-network:"
    docker network inspect llm-network --format='{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{println}}{{end}}'
    
    echo
}

# Funkcja do wyświetlania statusu noVNC
check_novnc_status() {
    echo -e "${BOLD}Status noVNC:${NC}"
    
    # Sprawdzanie, czy kontener noVNC istnieje i działa
    if check_container "novnc" > /dev/null; then
        echo -e "${GREEN}noVNC jest dostępny pod adresem: http://localhost:6080${NC}"
        echo -e "Hasło: password"
    else
        echo -e "${RED}noVNC nie jest dostępny.${NC}"
    fi
    
    echo
}

# Funkcja do wyświetlania statusu przeglądarki
check_browser_status() {
    echo -e "${BOLD}Status przeglądarki:${NC}"
    
    # Sprawdzanie, czy kontener przeglądarki istnieje i działa
    if check_container "browser" > /dev/null; then
        echo -e "${GREEN}Przeglądarka Firefox jest uruchomiona wewnątrz noVNC.${NC}"
        echo -e "Strona testowa: file:///config/test_llm.html"
    else
        echo -e "${RED}Przeglądarka nie jest dostępna.${NC}"
    fi
    
    echo
}

# Funkcja do wyświetlania podsumowania
show_summary() {
    echo -e "${BOLD}Podsumowanie:${NC}"
    
    # Sprawdzanie statusu kontenerów
    local model_service_status=$(check_container "llm-model-service" > /dev/null && echo "Działa" || echo "Nie działa")
    local api_gateway_status=$(check_container "llm-api-gateway" > /dev/null && echo "Działa" || echo "Nie działa")
    local novnc_status=$(check_container "novnc" > /dev/null && echo "Działa" || echo "Nie działa")
    local browser_status=$(check_container "browser" > /dev/null && echo "Działa" || echo "Nie działa")
    
    # Sprawdzanie statusu API
    local api_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health)
    local api_status="Niedostępne"
    if [ "$api_response" == "200" ]; then
        api_status="Dostępne"
    elif [ "$api_response" == "503" ]; then
        api_status="Uruchamianie"
    fi
    
    # Sprawdzanie statusu modelu
    local model_status="Nieznany"
    if docker logs llm-model-service 2>&1 | grep -q "Model loaded successfully"; then
        model_status="Załadowany"
    elif docker logs llm-model-service 2>&1 | grep -q "Loading model"; then
        model_status="Ładowanie"
    fi
    
    # Wyświetlanie podsumowania
    echo -e "Model Service: ${model_service_status}"
    echo -e "API Gateway: ${api_gateway_status}"
    echo -e "noVNC: ${novnc_status}"
    echo -e "Przeglądarka: ${browser_status}"
    echo -e "Status API: ${api_status}"
    echo -e "Status modelu: ${model_status}"
    
    echo
}

# Funkcja do wyświetlania pomocy
show_help() {
    echo -e "${BOLD}Monitorowanie systemu LLM${NC}"
    echo -e "Użycie: $0 [opcja]"
    echo -e "Opcje:"
    echo -e "  -h, --help     Wyświetla tę pomoc"
    echo -e "  -l, --live     Uruchamia monitorowanie w trybie ciągłym (aktualizacja co 5 sekund)"
    echo -e "  -s, --summary  Wyświetla tylko podsumowanie statusu"
    echo -e "  -a, --api      Wyświetla szczegółowe informacje o API"
    echo -e "  -m, --model    Wyświetla szczegółowe informacje o modelu"
    echo -e "  -n, --network  Wyświetla informacje o sieci"
    echo -e "  -v, --novnc    Wyświetla informacje o noVNC i przeglądarce"
    echo -e "  -c, --containers Wyświetla statystyki kontenerów"
    echo
    echo -e "Bez opcji, skrypt wyświetli wszystkie informacje jednorazowo."
    echo
}

# Funkcja do wyświetlania wszystkich informacji
show_all() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== MONITOROWANIE SYSTEMU LLM ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    show_summary
    
    # Sprawdzanie statusu kontenerów
    echo -e "${BOLD}${BLUE}=== KONTENERY ===${NC}"
    check_container "llm-model-service" && show_container_stats "llm-model-service"
    check_container "llm-api-gateway" && show_container_stats "llm-api-gateway"
    
    # Sprawdzanie statusu API i modelu
    echo -e "${BOLD}${BLUE}=== API I MODEL ===${NC}"
    check_api_status
    check_model_loading_progress
    
    # Sprawdzanie statusu noVNC i przeglądarki
    echo -e "${BOLD}${BLUE}=== NOVNC I PRZEGLĄDARKA ===${NC}"
    check_novnc_status
    check_browser_status
    
    # Sprawdzanie ruchu sieciowego
    echo -e "${BOLD}${BLUE}=== SIEĆ ===${NC}"
    check_network_traffic
    
    # Wyświetlanie ostatnich logów
    echo -e "${BOLD}${BLUE}=== OSTATNIE LOGI ===${NC}"
    echo -e "${BOLD}Model Service:${NC}"
    show_container_logs "llm-model-service" 10
    echo -e "${BOLD}API Gateway:${NC}"
    show_container_logs "llm-api-gateway" 10
}

# Funkcja do wyświetlania tylko podsumowania
show_only_summary() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== PODSUMOWANIE STATUSU SYSTEMU LLM ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    show_summary
}

# Funkcja do wyświetlania tylko informacji o API
show_only_api() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== STATUS API ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    check_api_status
    show_container_logs "llm-api-gateway" 20
}

# Funkcja do wyświetlania tylko informacji o modelu
show_only_model() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== STATUS MODELU ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    check_model_loading_progress
    show_container_logs "llm-model-service" 20
}

# Funkcja do wyświetlania tylko informacji o sieci
show_only_network() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== STATUS SIECI ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    check_network_traffic
}

# Funkcja do wyświetlania tylko informacji o noVNC i przeglądarce
show_only_novnc() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== STATUS NOVNC I PRZEGLĄDARKI ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    check_novnc_status
    check_browser_status
}

# Funkcja do wyświetlania tylko statystyk kontenerów
show_only_containers() {
    clear_screen
    echo -e "${BOLD}${BLUE}=== STATYSTYKI KONTENERÓW ===${NC}"
    echo -e "${BLUE}Data: $(date)${NC}"
    echo
    
    check_container "llm-model-service" && show_container_stats "llm-model-service"
    check_container "llm-api-gateway" && show_container_stats "llm-api-gateway"
    check_container "novnc" && show_container_stats "novnc"
    check_container "browser" && show_container_stats "browser"
}

# Główna funkcja
main() {
    # Sprawdzanie argumentów
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--live)
            # Monitorowanie w trybie ciągłym
            while true; do
                show_all
                echo -e "${YELLOW}Aktualizacja za 5 sekund... (Naciśnij Ctrl+C, aby zakończyć)${NC}"
                sleep 5
            done
            ;;
        -s|--summary)
            show_only_summary
            ;;
        -a|--api)
            show_only_api
            ;;
        -m|--model)
            show_only_model
            ;;
        -n|--network)
            show_only_network
            ;;
        -v|--novnc)
            show_only_novnc
            ;;
        -c|--containers)
            show_only_containers
            ;;
        *)
            # Domyślnie wyświetl wszystkie informacje jednorazowo
            show_all
            ;;
    esac
}

# Uruchomienie głównej funkcji
main "$@"
