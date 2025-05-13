#!/bin/bash
# monitor.sh - Monitorowanie logów kontenerów Docker Compose i automatyczne reagowanie na błędy

# Lista słów kluczowych oznaczających błąd
ERROR_PATTERNS="error|fail|exception|fatal"

# Funkcja do kolorowania tekstu na czerwono
ered() { echo -e "\033[1;31m$1\033[0m"; }

echo "[INFO] Monitoruję logi wszystkich serwisów Docker Compose..."
echo "[INFO] Szukam wzorców: $ERROR_PATTERNS (case-insensitive)"
echo "[INFO] Naciśnij Ctrl+C, aby zakończyć."

docker compose logs -f 2>&1 | while read -r line; do
    # Szukaj błędów w linii (case-insensitive)
    if [[ "$line" =~ $ERROR_PATTERNS ]]; then
        # Wyciągnij nazwę serwisu (jeśli jest w formacie logów Compose)
        service=$(echo "$line" | awk -F'|' '{print $1}' | awk '{print $2}')
        ered "[BŁĄD] $line"
        # Przykładowa automatyczna reakcja na znane błędy
        if [[ "$line" =~ "Address already in use" ]]; then
            ered "[AUTO] Wykryto konflikt portu w serwisie $service. Restartuję..."
            if [ -n "$service" ]; then
                docker compose restart "$service"
            fi
        fi
        # Możesz dodać tu kolejne automatyczne reakcje na inne znane błędy
    fi
    # Możesz dodać tu inne akcje monitorujące
    # Np. powiadomienia mailowe, webhooki, itp.
done
