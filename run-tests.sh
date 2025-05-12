#!/bin/bash
# run-tests.sh

# Kolory do komunikatów
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== System testowy AutoFormFiller ====${NC}\n"

# Sprawdź, czy system jest uruchomiony
if ! docker ps | grep -q "llm-orchestrator"; then
    echo -e "${RED}System AutoFormFiller nie jest uruchomiony.${NC}"
    echo -e "Uruchom najpierw główny system poleceniem ./run.sh"
    exit 1
fi

# Przygotuj katalog na wyniki testów
mkdir -p volumes/test-results

# Pokaż menu testów
echo -e "${GREEN}Dostępne opcje testowe:${NC}"
echo "1) Uruchom wszystkie testy"
echo "2) Test prostego formularza"
echo "3) Test złożonego formularza wielojęzycznego"
echo "4) Test formularza z uploadem plików"
echo "5) Tylko wygeneruj dane testowe (bez uruchamiania testów)"
echo "6) Zakończ"

read -p "Wybierz opcję (1-6): " OPTION

case $OPTION in
    1)
        echo -e "${GREEN}Uruchamiam wszystkie testy...${NC}"
        docker-compose exec test-runner python /app/tests/run-tests.py
        ;;
    2)
        echo -e "${GREEN}Uruchamiam test prostego formularza...${NC}"
        docker-compose exec test-runner python /app/tests/test-simple-form.py
        ;;
    3)
        echo -e "${GREEN}Uruchamiam test złożonego formularza wielojęzycznego...${NC}"
        docker-compose exec test-runner python /app/tests/test-complex-form.py
        ;;
    4)
        echo -e "${GREEN}Uruchamiam test formularza z uploadem plików...${NC}"
        docker-compose exec test-runner python /app/tests/test-file-upload.py
        ;;
    5)
        echo -e "${GREEN}Generuję dane testowe...${NC}"
        docker-compose exec test-runner python /app/tests/run-tests.py --generate-only
        ;;
    6)
        echo -e "${GREEN}Zakończono.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Nieprawidłowa opcja.${NC}"
        exit 1
        ;;
esac

# Pokaż informacje o wynikach testów
echo -e "\n${GREEN}=== Podsumowanie testów ===${NC}"
echo -e "${YELLOW}Wyniki testów dostępne w katalogu:${NC} volumes/test-results"
echo -e "${YELLOW}Aby otworzyć zrzuty ekranu z testów, przejdź do powyższego katalogu.${NC}"