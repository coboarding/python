#!/bin/bash
# test-service.sh <service-name>
# Skrypt do testowania pojedynczego serwisu Docker
set -e

SERVICE="$1"
if [ -z "$SERVICE" ]; then
  echo "Użycie: $0 <service-name>"
  exit 1
fi

COMPOSE_FILE="docker-compose.$SERVICE.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Brak pliku $COMPOSE_FILE! Utwórz docker-compose.<service>.yml dla każdego serwisu."
  exit 2
fi

echo "[INFO] Buduję i uruchamiam środowisko dla: $SERVICE..."
docker-compose -f "$COMPOSE_FILE" up --build -d

# Czekaj na start kontenera (możesz rozwinąć o healthcheck)
sleep 5

echo "[INFO] Testuję serwis: $SERVICE..."
# Przykładowy test: sprawdź czy kontener działa
if docker-compose -f "$COMPOSE_FILE" ps | grep -q 'Up'; then
  echo "[OK] Kontener $SERVICE działa."
else
  echo "[FAIL] Kontener $SERVICE nie działa!"
  docker-compose -f "$COMPOSE_FILE" logs
  docker-compose -f "$COMPOSE_FILE" down
  exit 3
fi

# (Opcjonalnie) Dodaj własne testy HTTP/API dla danego serwisu tutaj
# Przykład dla llm-orchestrator:
if [ "$SERVICE" = "llm-orchestrator" ]; then
  curl -f http://localhost:5000/health && echo "[OK] Healthcheck passed." || echo "[FAIL] Healthcheck failed!"
fi

# Wyświetl logi
echo "[INFO] Logi serwisu $SERVICE:"
docker-compose -f "$COMPOSE_FILE" logs

# Zatrzymaj środowisko
echo "[INFO] Zatrzymuję środowisko $SERVICE..."
docker-compose -f "$COMPOSE_FILE" down
